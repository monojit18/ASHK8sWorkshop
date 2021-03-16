param([Parameter(Mandatory=$true)]  [string] $mode,
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "ash-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "azs001",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "ash-workshop-kv",      
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "f581d2c5-6e46-41b1-a965-47588f4b857a",
      [Parameter(Mandatory=$false)] [string] $nodePoolConfigFileName = "ash-nodepool",
      [Parameter(Mandatory=$false)] [string] $nodepoolName = "ashapipool",
      [Parameter(Mandatory=$false)] [string] $newNodeCount = 3,
      [Parameter(Mandatory=$false)] [string] $apiServer = "https://12.0.1.10",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "C:\Users\azureuser\Developments\Projects\ASHK8sWorkshop\Deployments") # Till Deployments

$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"
$outputFolderPath = $templatesFolderPath + "/AKSEngine/Output/ClusterInfo"

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$kvShowAppIdCommand = "az keyvault secret show -n $aksSPIdName --vault-name $keyVaultName --query 'value' -o tsv"
$spAppId = Invoke-Expression -Command $kvShowAppIdCommand
if (!$spAppId)
{
      Write-Host "Error fetching Service Principal Id"
      return;
}

$kvShowSecretCommand = "az keyvault secret show -n $aksSPSecretName --vault-name $keyVaultName --query 'value' -o tsv"
$spPassword = Invoke-Expression -Command $kvShowSecretCommand
if (!$spPassword)
{
      Write-Host "Error fetching Service Principal Password"
      return;
}

if ($mode -eq "add")
{
      
      $deployCommand = "aks-engine-554 addpool -m '$outputFolderPath/apimodel.json' --azure-env 'AzureStackCloud' -g $resourceGroup -l $location --client-id '$spAppId' --client-secret '$spPassword' -p '$templatesFolderPath/AKSEngine/$nodePoolConfigFileName.json'"
      Invoke-Expression -Command $deployCommand

}
elseif ($mode -eq "scale")
{
      
      $scaleCommand = "aks-engine-554 scale -m '$outputFolderPath/apimodel.json' --azure-env 'AzureStackCloud' -g $resourceGroup -l $location --client-id '$spAppId' --client-secret '$spPassword' --node-pool $nodepoolName --new-node-count $newNodeCount"
      Invoke-Expression -Command $scaleCommand

}
elseif ($mode -eq "scale-in")
{
      
      $scaleCommand = "aks-engine-554 scale -m '$outputFolderPath/apimodel.json' --azure-env 'AzureStackCloud' -g $resourceGroup -l $location --client-id '$spAppId' --client-secret '$spPassword' --node-pool $nodepoolName --new-node-count $newNodeCount --apiserver $apiServer"
      Invoke-Expression -Command $scaleCommand

}


Write-Host "-----------Setup------------"