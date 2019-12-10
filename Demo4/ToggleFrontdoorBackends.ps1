param (
    [Parameter(Mandatory)]
    [string]$frontDoorResourceGroup,
    [Parameter(Mandatory)]
    [string]$frontDoorName,
    [Parameter(Mandatory)]
    [string]$frontDoorBackendPoolName,
    [Parameter(Mandatory)]
    [string]$frontDoorUrl,
    [Parameter(Mandatory)]
    [string]$webAppBlueUrl,
    [Parameter(Mandatory)]
    [string]$webAppGreenUrl,
    [Parameter(Mandatory=$false)]
    [bool]$loginWithServicePrincipal = $false,
    [Parameter(Mandatory=$false)]
    [string]$spUsername = '',
    [Parameter(Mandatory=$false)]
    [string]$spPassword = '',
    [Parameter(Mandatory=$false)]
    [string]$tenant = ''
)
$(get-date)
function ListFrontdoorBackEnds () 
{
    az network front-door backend-pool backend list --front-door-name $frontDoorName --pool-name $frontDoorBackendPoolName --resource-group $frontDoorResourceGroup -o table
}

if ($loginWithServicePrincipal) {
    Write-Host "Loggin in with Service Principal..."
    az login --service-principal -u $spUsername -p $spPassword --tenant $tenant
}

#Frontdoor extension currently in preview
az extension add --name front-door

#Find the current web app (blue/green), and set the target release environment
$response = Invoke-WebRequest $frontDoorUrl -UseBasicParsing -Method Head
$currentDeploymentWebApp = If ($response.Headers["set-cookie"] -like "*Domain=$webAppBlueUrl*") {$webAppBlueUrl} Else {$webAppGreenUrl}
$targetDeploymentWebApp = If ($response.Headers["set-cookie"] -like "*Domain=$webAppGreenUrl*") {$webAppBlueUrl} Else {$webAppGreenUrl}
Write-Host "Set-Cookie: " $response.Headers["set-cookie"]
Write-Host "Current Backend running: $currentDeploymentWebApp"
Write-Host "Target Backend: $targetDeploymentWebApp"
ListFrontdoorBackEnds

#Convert Front Door Front Backend Address to Array
$addresses = (az network front-door backend-pool backend list --front-door-name $frontDoorName --pool-name $frontDoorBackendPoolName --resource-group $frontDoorResourceGroup --query '[].{Address:address}' -o tsv)
foreach ($address in $addresses) {
    Write-Host "Front door backend: $address"
}

#Switch Azure Frontdoor backends between blue and green by changing priority
Write-Host "Set current backend priority to 2" # Limitation in Azure CLI to update a backend. Workaround to remove and add backend again.
$currentBackendAddressindex = $addresses.indexOf($currentDeploymentWebApp)
if ($currentBackendAddressindex -ge 0) {
    $currentBackendAddressIndex = ($addresses.indexOf($currentDeploymentWebApp) + 1)
    Write-Host "Current backend address found at index $currentBackendAddressIndex... Changing priority to 2"
    az network front-door backend-pool backend remove --front-door-name $frontDoorName --index $currentBackendAddressIndex --pool-name $frontDoorBackendPoolName --resource-group $frontDoorResourceGroup -o table
    az network front-door backend-pool backend add --address $currentDeploymentWebApp --front-door-name $frontDoorName --pool-name $frontDoorBackEndPoolName --resource-group $frontDoorResourceGroup --priority 2
    ListFrontdoorBackEnds
} else 
{
    Write-Host "$currentDeploymentWebApp not found in list of backends... adding backend"
    az network front-door backend-pool backend add --address $currentDeploymentWebApp --front-door-name $frontDoorName --pool-name $frontDoorBackEndPoolName --resource-group $frontDoorResourceGroup --priority 2
}

$targetaddressindex = $addresses.indexOf($targetDeploymentWebApp)
Write-Host "Set target backend priority to 1" # Limitation in Azure CLI to update a backend. Workaround to remove and add backend again.
$targetBackendAddressindex = $addresses.indexOf($targetDeploymentWebApp)
if ($targetBackendAddressindex -ge 0) {
    $targetBackendAddressIndex = ($addresses.indexOf($targetDeploymentWebApp) + 1)
    Write-Host "Target backend address found at index $targetBackendAddressIndex... Changing priority to 1"
    az network front-door backend-pool backend remove --front-door-name $frontDoorName --index $targetBackendAddressIndex --pool-name $frontDoorBackendPoolName --resource-group $frontDoorResourceGroup -o table
    az network front-door backend-pool backend add --address $targetDeploymentWebApp --front-door-name $frontDoorName --pool-name $frontDoorBackEndPoolName --resource-group $frontDoorResourceGroup --priority 1
    ListFrontdoorBackEnds
} else 
{
    Write-Host "$targetDeploymentWebApp not found in list of backends... adding backend"
    az network front-door backend-pool backend add --address $targetDeploymentWebApp --front-door-name $frontDoorName --pool-name $frontDoorBackEndPoolName --resource-group $frontDoorResourceGroup --priority 1
}
$(get-date)
#Wait for Front Door Load Balancer switch of environments to go live!
$StartTime = $(get-date)
DO
{
    $response = Invoke-WebRequest $frontDoorUrl -UseBasicParsing -Method Head
    $CurrentTime = $(get-date)
    $elapsedTime = $CurrentTime - $StartTime
    $totalSeconds = [math]::floor($elapsedTime.TotalSeconds)
    Write-Host "$totalSeconds..." $response.Headers["set-cookie"]
    Start-Sleep -s 1
} Until ($response.Headers["set-cookie"] -like "*Domain=$targetDeploymentWebApp*")