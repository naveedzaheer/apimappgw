# search for : root ca for self signed cert
$rgname = "nzapimpattern-rg"
$location = "EastUS2"
$kv = "nzapim-kv"
$appgwName = "apim-gw"
$gatewayHostname = "api.nzazuredemo.com"                 # API gateway host
$portalHostname = "portal.nzazuredemo.com"               # API developer portal host
$mgmtHostname = "management.nzazuredemo.com"               # API developer portal host

$identity = Get-AzUserAssignedIdentity -Name "att-kv-user" -ResourceGroupName $rgname
$apimService = Get-AzApiManagement -Name "nzapimpatterndemo" -ResourceGroupName $rgname
$vnet = Get-AzVirtualNetwork -Name "nzapimpattern-vnet" -ResourceGroupName $rgname
$gwSubnet = Get-AzVirtualNetworkSubnetConfig -Name "appagw-subnet" -VirtualNetwork $vnet
$publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name "nzapimgw-ip"

$gipconfig = New-AzApplicationGatewayIPConfiguration -Name "AppGwIpConfig" -Subnet $gwSubnet
$fipconfig01 = New-AzApplicationGatewayFrontendIPConfig -Name "fipconfig" -PublicIPAddress $publicip
$fp01 = New-AzApplicationGatewayFrontendPort -Name "port01"  -Port 443

# Please import the certs into KV before this
$cert = New-AzApplicationGatewaySslCertificate -Name "gwcert" -KeyVaultSecretId "https://nzapim-kv.vault.azure.net/secrets/apigateway/"
$certPortal = New-AzApplicationGatewaySslCertificate -Name "portalcert" -KeyVaultSecretId "https://nzapim-kv.vault.azure.net/secrets/apimportal/"
$certMgmt = New-AzApplicationGatewaySslCertificate -Name "mgmtcert" -KeyVaultSecretId "https://nzapim-kv.vault.azure.net/secrets/apimmgmt/"

$listener = New-AzApplicationGatewayHttpListener -Name "listener01" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -HostName $gatewayHostname -RequireServerNameIndication true
$portalListener = New-AzApplicationGatewayHttpListener -Name "listener02" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certPortal -HostName $portalHostname -RequireServerNameIndication true
$managementListener = New-AzApplicationGatewayHttpListener -Name "listener03" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certMgmt -HostName $portalHostname -RequireServerNameIndication true

$apimprobe = New-AzApplicationGatewayProbeConfig -Name "apimproxyprobe" -Protocol "Https" -HostName $gatewayHostname -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
$apimPortalProbe = New-AzApplicationGatewayProbeConfig -Name "apimportalprobe" -Protocol "Https" -HostName $portalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8
$apimMgmtProbe = New-AzApplicationGatewayProbeConfig -Name "apimmgmtprobe" -Protocol "Https" -HostName $mgmtHostname -Path "/ServiceStatus" -Interval 60 -Timeout 300 -UnhealthyThreshold 8

$authcert = New-AzApplicationGatewayTrustedRootCertificate -Name "whitelistcert" -CertificateFile "C:\NZ\VSTS\APIM-AppGW-KV\CACerts\nzazuredemo.pem"

$apimPoolSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimprobe -RequestTimeout 180 -TrustedRootCertificate $authcert -HostName "api.nzazuredemo.com"
$apimPoolPortalSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolPortalSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimPortalProbe -RequestTimeout 180 -TrustedRootCertificate $authcert -HostName "portal.nzazuredemo.com"
$apimPoolMgmtSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolMgmtSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimMgmtProbe -RequestTimeout 180 -TrustedRootCertificate $authcert -HostName "management.nzazuredemo.com"

$apimProxyBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "apimbackend" -BackendIPAddresses $apimService.PrivateIPAddresses[0]

$rule01 = New-AzApplicationGatewayRequestRoutingRule -Name "rule1" -RuleType Basic -HttpListener $listener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolSetting
$rule02 = New-AzApplicationGatewayRequestRoutingRule -Name "rule2" -RuleType Basic -HttpListener $portalListener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolPortalSetting
$rule03 = New-AzApplicationGatewayRequestRoutingRule -Name "rule3" -RuleType Basic -HttpListener $managementListener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolMgmtSetting

$sku = New-AzApplicationGatewaySku -Name WAF_v2 -Tier WAF_v2 -Capacity 1

$appgwIdentity = New-AzApplicationGatewayIdentity -UserAssignedIdentityId $identity.Id

#$config = New-AzApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Prevention"
#$autoscaleConfig = New-AzApplicationGatewayAutoscaleConfiguration -MinCapacity 2

# with firewall and auto scale
#$appgw = New-AzApplicationGateway -Name $appgwName -Identity $appgwIdentity -ResourceGroupName $rgname -Location $location -BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $apimPoolSetting, $apimPoolPortalSetting  -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener, $portalListener -RequestRoutingRules $rule01, $rule02 -Sku $sku -WebApplicationFirewallConfig $config -SslCertificates $cert, $certPortal -Probes $apimprobe, $apimPortalProbe -AutoscaleConfiguration  $autoscaleConfig -TrustedRootCertificate $authcert

# without firewall and auto scale
$appgw = New-AzApplicationGateway -Name $appgwName -Identity $appgwIdentity -ResourceGroupName $rgname -Location $location -BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $apimPoolSetting, $apimPoolPortalSetting, $apimPoolMgmtSetting  -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener, $portalListener, $managementListener -RequestRoutingRules $rule01, $rule02, $rule03 -Sku $sku -SslCertificates $cert, $certPortal, $certMgmt -Probes $apimprobe, $apimPortalProbe, $apimMgmtProbe -TrustedRootCertificate $authcert
