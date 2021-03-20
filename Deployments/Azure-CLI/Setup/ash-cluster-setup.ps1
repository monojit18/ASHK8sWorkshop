# /*
#  * 
#  * Copyright 2021 Monojit Datta

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#        http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#  *
# */

param([Parameter(Mandatory=$false)] [string] $resourceGroup = "ash-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "<stack_hub_location>",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "ash-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $ashVNetName = "ash-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $ashSubnetName = "ash-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $clientAppID = "<client_App_ID>",
      [Parameter(Mandatory=$false)] [string] $serverAppID = "<server_App_ID>",
      [Parameter(Mandatory=$false)] [string] $adminGroupID = "<admin_Group_ID>",
      [Parameter(Mandatory=$false)] [string] $tenantID = "<tenant_ID>",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscription_Id>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<base_Folder_Path>") # Till Deployments

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