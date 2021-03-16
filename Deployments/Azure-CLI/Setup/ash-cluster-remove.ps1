param([Parameter(Mandatory=$false)] [string] $resourceGroup = "ash-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $bastionResourceGroup = "Inshorts-POC2",
      [Parameter(Mandatory=$false)] [string] $ashVNetName = "ash-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $bastionVNetName = "master-hub-vnet",      
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "f581d2c5-6e46-41b1-a965-47588f4b857a")

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