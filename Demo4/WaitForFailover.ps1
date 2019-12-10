param (
    [Parameter(Mandatory)]
    [string]$frontDoorUrl
)

$StartTime = $(get-date)
DO
{
    $req = [system.Net.WebRequest]::Create($frontDoorUrl)
    try {
        $res = $req.GetResponse()
    } 
    catch [System.Net.WebException] {
        $res = $_.Exception.Response
    }
    $CurrentTime = $(get-date)
    $elapsedTime = $CurrentTime - $StartTime
    $totalSeconds = [math]::floor($elapsedTime.TotalSeconds)
    $statusCode = [int]$res.StatusCode
    Write-Host "$totalSeconds...$statusCode"
    Start-Sleep -s 1
} Until ([int]$res.StatusCode -eq 200)