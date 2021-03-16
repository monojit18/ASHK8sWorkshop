param([Parameter(Mandatory=$false)] [string] $resourceGroup = "ash-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "azs001",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "ash-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $ashVNetName = "ash-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $ashSubnetName = "ash-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $clientAppID = "70dba699-0fba-4c1d-805e-213acea0a63e",
      [Parameter(Mandatory=$false)] [string] $serverAppID = "3adf37ca-d914-43e9-9b24-8c081e0b3a08",
      [Parameter(Mandatory=$false)] [string] $adminGroupID = "6ec3a0a8-a6c6-4cdf-a6e3-c296407a5ec1",
      [Parameter(Mandatory=$false)] [string] $tenantID = "3851f269-b22b-4de6-97d6-aa9fe60fe301",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "f581d2c5-6e46-41b1-a965-47588f4b857a",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "C:\Users\azureuser\Developments\Projects\ASHK8sWorkshop\Deployments") # Till Deployments

$ashSPIdName = $clusterName + "-sp-id"
$ashSPSecretName = $clusterName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"
$outputFolderPath = $templatesFolderPath + "/AKSEngine/Output/ClusterInfo"

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$kvShowAppIdCommand = "az keyvault secret show -n $ashSPIdName --vault-name $keyVaultName --query 'value' -o tsv"
$spAppId = Invoke-Expression -Command $kvShowAppIdCommand
if (!$spAppId)
{
      Write-Host "Error fetching Service Principal Id"
      return;
}

$kvShowSecretCommand = "az keyvault secret show -n $ashSPSecretName --vault-name $keyVaultName --query 'value' -o tsv"
$spPassword = Invoke-Expression -Command $kvShowSecretCommand
if (!$spPassword)
{
      Write-Host "Error fetching Service Principal Password"
      return;
}

$networkShowCommand = "az network vnet subnet show -n $ashSubnetName --vnet-name $ashVNetName -g $resourceGroup --query 'id' -o tsv"
$ashVnetSubnetId = Invoke-Expression -Command $networkShowCommand
if (!$ashVnetSubnetId)
{

      Write-Host "Error fetching Vnet"
      return;

}

$genericSetCommand = "--set masterProfile.dnsPrefix=$clusterName"
$aadSetCommand = ",aadProfile.clientAppID=$clientAppID,aadProfile.serverAppID=$serverAppID,aadProfile.adminGroupID=$adminGroupID,aadProfile.tenantID=$tenantID"
$vnetSubnetSetCommand = ",masterProfile.vnetSubnetId='$ashVnetSubnetId',agentPoolProfiles[0].vnetSubnetId='$ashVnetSubnetId',agentPoolProfiles[1].vnetSubnetId='$ashVnetSubnetId',agentPoolProfiles[2].vnetSubnetId='$ashVnetSubnetId'"
$parametersSetCommand = $genericSetCommand + $aadSetCommand + $vnetSubnetSetCommand
$deployCommand = "aks-engine-554 deploy -m '$templatesFolderPath/AKSEngine/ash-config.json' --azure-env 'AzureStackCloud' -g $resourceGroup -l $location --client-id '$spAppId' --client-secret '$spPassword' $parametersSetCommand -o '$outputFolderPath' -f --auto-suffix"
Invoke-Expression -Command $deployCommand

Write-Host "-----------Setup------------"