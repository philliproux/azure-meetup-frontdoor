#Manually turn on session affinity - Bug in Front Door CLI
#URLs

#Front door: https://azure-meetup-frontdoor-demo4.azurefd.net/
#Web app - Blue: https://azure-meetup-frontdoor-demo4-web-app-blue.azurewebsites.net/
#Web app - Green: https://azure-meetup-frontdoor-demo4-web-app-green.azurewebsites.net/

exit
.\DeployInfra.ps1 -frontDoorResourceGroup "azure-meetup-frontdoor-demo4" -frontDoorName "azure-meetup-frontdoor-demo4" -webAppBlue "azure-meetup-frontdoor-demo4-web-app-blue" -webAppGreen "azure-meetup-frontdoor-demo4-web-app-green" -webAppBlueUrl "azure-meetup-frontdoor-demo4-web-app-blue.azurewebsites.net" -webAppGreenUrl "azure-meetup-frontdoor-demo4-web-app-green.azurewebsites.net" -appServicePlanBlue "azure-meetup-frontdoor-demo4-web-appserviceplan-blue" -appServicePlanGreen "azure-meetup-frontdoor-demo4-web-appserviceplan-green" -appServicePlanSize "D1"

exit
# Toggle Blue and Green Backends
.\ToggleFrontdoorBackends.ps1 -frontDoorResourceGroup "azure-meetup-frontdoor-demo4" -frontDoorName "azure-meetup-frontdoor-demo4" -frontDoorBackendPoolName "DefaultBackendPool" -frontDoorUrl "https://azure-meetup-frontdoor-demo4.azurefd.net" -webAppBlueUrl "azure-meetup-frontdoor-demo4-web-app-blue.azurewebsites.net" -webAppGreenUrl "azure-meetup-frontdoor-demo4-web-app-green.azurewebsites.net"

exit
# Failover/Online Check
.\WaitForFailover.ps1 -frontdoorUrl "https://azure-meetup-frontdoor-demo4.azurefd.net/"