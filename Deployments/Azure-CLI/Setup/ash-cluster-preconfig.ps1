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
      [Parameter(Mandatory=$false)] [string] $bastionResourceGroup = "<bastion_Resource_Group>",
      [Parameter(Mandatory=$false)] [string] $location = "<stack_hub_location>",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "ash-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $bastionVNetName = "master-hub-vnet",
      [Parameter(Mandatory=$false)] [string] $ashVNetName = "ash-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $ashVNetPrefix = "12.0.0.0/16",
      [Parameter(Mandatory=$false)] [string] $ashSubnetName = "ash-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $ashSubnetPrefix = "12.0.0.0/21",
      [Parameter(Mandatory=$false)] [string] $kvTemplateFileName = "ash-keyvault-deploy",
      [Parameter(Mandatory=$false)] [string] $networkTemplateFileName = "ash-network-deploy",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscription_Id>",
      [Parameter(Mandatory=$false)] [string] $objectId = "<object_Id>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<base_Folder_Path>") # Till Deployments

$aksSPDisplayName = $clusterName + "-sp"
$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"

# Assuming Logged In

$rgShowCommand = "az group show --name $resourceGroup --subscription $subscriptionId --query 'id' -o json"
$rgCreateCommand = "az group create --name $resourceGroup -l $location --subscription $subscriptionId --query='id'"

$networkShowCommand = "az network vnet show -n $ashVNetName -g $resourceGroup --query 'id' -o json"
$networkNames = "ashVNetName=$ashVNetName ashVNetPrefix=$ashVNetPrefix ashSubnetName=$ashSubnetName ashSubnetPrefix=$ashSubnetPrefix"
$networkDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/Network/$networkTemplateFileName.json --parameters $networkNames"

$keyVaultShowCommand = "az keyvault show -n $keyVaultName --query 'id' -o json"
$keyVaultDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/KeyVault/$kvTemplateFileName.json --parameters keyVaultName=$keyVaultName objectId=$objectId"

$spShowCommand = "az ad sp show --id http://$aksSPDisplayName --query 'appId'"

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$rgRef = Invoke-Expression -Command $rgShowCommand
if (!$rgRef)
{
   $rgRef = Invoke-Expression -Command $rgCreateCommand
   if (!$rgRef)
   {
        Write-Host "Error creating Resource Group"
        return;
   }

   Write-Host $rgRef

}

$ashVnet = Invoke-Expression -Command $networkShowCommand
if (!$ashVnet)
{

    Invoke-Expression -Command $networkDeployCommand
    $ashVnet = Invoke-Expression -Command $networkShowCommand
    Write-Host $ashVnet

    $bstnVnetShowCommand = "az network vnet show -n $bastionVNetName -g $bastionResourceGroup --query 'id' -o json"
    $bstnVnet = Invoke-Expression -Command $bstnVnetShowCommand
    
    $vnetPeeringCommand = "az network vnet peering create -g $resourceGroup -n ash-master-peering --vnet-name $ashVNetName --remote-vnet '$bstnVnet' --allow-forwarded-traffic --allow-vnet-access"
    Invoke-Expression -Command $vnetPeeringCommand

    $vnetPeeringCommand = "az network vnet peering create -g $bastionResourceGroup -n master-ash-peering --vnet-name $bastionVNetName --remote-vnet '$ashVnet' --allow-forwarded-traffic --allow-vnet-access"
    Invoke-Expression -Command $vnetPeeringCommand

}

$keyVaultInfo = Invoke-Expression -Command $keyVaultShowCommand
if (!$keyVaultInfo)
{

    Invoke-Expression -Command $keyVaultDeployCommand
    $keyVaultInfo = Invoke-Expression -Command $keyVaultShowCommand
    Write-Host $keyVaultInfo

}

$azcSP = Invoke-Expression -Command $spShowCommand
if (!$azcSP)
{

    Write-Host "Error retrieving Service Principal"
    return;

}

$resourceGroupRoleCommand = "az role assignment create --assignee $azcSP --role 'Owner' --scope '/subscriptions/$subscriptionId/resourceGroups/$resourceGroup'"
Invoke-Expression -Command $resourceGroupRoleCommand

Write-Host "------------Pre-Config----------"
