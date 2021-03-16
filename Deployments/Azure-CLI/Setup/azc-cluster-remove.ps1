param([Parameter(Mandatory=$true)]  [string] $shouldRemoveSP = "false",
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "azc-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "61fbc32c-9633-42bf-bfb5-2a8b3aeed21d")

$aksSPName = $clusterName + "-sp"
$subscriptionCommand = "az account set -s $subscriptionId"

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

# Delete Resource Group
az group delete -g $resourceGroup --yes

if ($shouldRemoveSP -eq "true")
{

      $spDeleteCommand = "az ad sp delete --id http://$aksSPName"
      Invoke-Expression -Command $spDeleteCommand
        
}

Write-Host "-----------Remove------------"