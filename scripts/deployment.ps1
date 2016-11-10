function createResourceGroupIsNotExists($resourceGroup, $location){
  $result = Get-AzureRmResourceGroup | Select -ExpandProperty ResourceGroupName | Where-Object {$_ -eq $resourceGroup}
  
  if ($result){
    Write-Host "Resource group $($resourceGroup) found."
    return;
  }
   
  Write-Host "Creating resource group $($resourceGroup) in location $($location)"
  New-AzureRmResourceGroup -Name $resourceGroup -Location $location 
}

#Create the resource group  for the sql server
createResourceGroupIsNotExists "svibor" "West Europe"

$sqlServerResult = New-AzureRmResourceGroupDeployment -ResourceGroupName "svibor" -TemplateFile "../templates/sqlserver.json" -Name "sqlserverdeployment"
$sqlServerResult | Out-String

if ($sqlServerResult.ProvisioningState -eq "Failed"){
    Write-Host "Something went wrong , stopping deployment"
    exit 1
}

#Create the resource group for the App Service/Plan
createResourceGroupIsNotExists "perun" "West Europe"

$parameters = @{"SqlServerFQDN" = $sqlServerResult.Outputs.sqlServerFQDN.Value;
                "SqlServerName" = $sqlServerResult.Outputs.sqlServerName.Value; 
                "SqlServerAdminLogin" = $sqlServerResult.Outputs.sqlServerAdminLogin.Value;
                "SqlServerPassword" = $sqlServerResult.Outputs.sqlServerPassword.Value;
                "DatabaseName" = $sqlServerResult.Outputs.databaseName.Value;}

$parameters | Out-String

$appServiceResult = New-AzureRmResourceGroupDeployment -ResourceGroupName "perun" -TemplateFile "../templates/appservice.json" -Name "sqlserverdeployment" -TemplateParameterObject $parameters
$appServiceResult | Out-String