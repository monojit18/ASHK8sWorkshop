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
      [Parameter(Mandatory=$false)] [string] $ashVNetName = "ash-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $bastionVNetName = "master-hub-vnet",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscription_Id>")

$subscriptionCommand = "az account set -s $subscriptionId"

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

$networkShowCommand = "az network vnet show -n $bastionVNetName -g $bastionResourceGroup --query 'id' -o json"
$bstnVnet = Invoke-Expression -Command $networkShowCommand
if ($bstnVnet)
{
      $vnetPeeringCommand = "az network vnet peering delete -g $resourceGroup -n ash-master-peering --vnet-name $ashVNetName"
      Invoke-Expression -Command $vnetPeeringCommand
}

$networkShowCommand = "az network vnet show -n $ashVNetName -g $resourceGroup --query 'id' -o json"
$ashVnet = Invoke-Expression -Command $networkShowCommand
if ($ashVnet)
{
      $vnetPeeringCommand = "az network vnet peering delete -g $bastionResourceGroup -n master-ash-peering --vnet-name $bastionVNetName"
      Invoke-Expression -Command $vnetPeeringCommand
}

# Delete Resource Group
az group delete -g $resourceGroup --yes

Write-Host "-----------Remove------------"