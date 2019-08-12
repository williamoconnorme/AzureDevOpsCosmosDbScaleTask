[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Import dependencies
Import-Module -Name .\ps_modules\Az.Accounts\1.2.1\Az.Accounts.psd1 -Force
Import-Module -Name .\ps_modules\Az.Resources\1.1.1\Az.Resources.psd1 -Force

# Set variables from task form input
$resourceGroupName = Get-VstsInput -Name "ResourceGroupName" -Require
$cosmosDbAccountName = Get-VstsInput -Name "cosmosDbAccountName" -Require
$databaseName = Get-VstsInput -Name "databaseName" -Require
$connectedServiceNameARM = Get-VstsInput -Name "ConnectedServiceNameARM" -Require
$throughputScaleInt = Get-VstsInput -Name "throughputScaleInt" -Require
$endPointRM = Get-VstsEndpoint -Name $connectedServiceNameARM -Require
$clientId = $endPointRM.Auth.Parameters.ServicePrincipalId
$clientSecret = $endPointRM.Auth.Parameters.ServicePrincipalKey
$tenantId = $endPointRM.Auth.Parameters.TenantId

# Authenticate using service principal
$password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($clientId, $password)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId 

# Cosmos config
$type = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$api = "2015-04-08"
$update = @{}
$update.Add("resource", @{"throughput" = $throughputScaleInt}) 

Write-Host "Scaling $databaseName throughput in $cosmosDbAccountName to $throughputScaleInt RU's"
Set-AzResource -ResourceType $type -ApiVersion $api -ResourceGroupName $resourceGroupName -Name "$cosmosDbAccountName/sql/$databaseName/throughput" -PropertyObject $update -Force | Out-Null