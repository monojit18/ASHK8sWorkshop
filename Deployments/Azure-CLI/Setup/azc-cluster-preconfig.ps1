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

param([Parameter(Mandatory=$false)] [string] $resourceGroup = "azc-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $acrName = "azcashacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "azc-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $logWorkspaceName = "azc-workshop-lw",
      [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "azc-acr-deploy",
      [Parameter(Mandatory=$false)] [string] $kvTemplateFileName = "azc-keyvault-deploy",
      [Parameter(Mandatory=$false)] [string] $lwTemplateFileName = "azc-lw-deploy",
      [Parameter(Mandatory=$false)] [string] $containerTemplateFileName = "containerSolution",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscription_Id>",
      [Parameter(Mandatory=$false)] [string] $objectId = "<object_Id>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<base_Folder_Path>") # Till Deployments

$azcSPDisplayName = $clusterName + "-sp"
$azcSPIdName = $clusterName + "-sp-id"
$azcSPSecretName = $clusterName + "-sp-secret"
$wsIdName = $clusterName + "-ws-id"
$wsSecretName = $clusterName + "-ws-secret"
$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"

# Assuming Logged In

$rgShowCommand = "az group show --name $resourceGroup --subscription $subscriptionId --query 'id' -o json"
$rgCreateCommand = "az group create --name $resourceGroup -l $location --subscription $subscriptionId --query='id'"

$acrShowCommand = "az acr show -n $acrName --query 'id' -o json"
$acrDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/ACR/$acrTemplateFileName.json --parameters acrName=$acrName"

$keyVaultShowCommand = "az keyvault show -n $keyVaultName --query 'id' -o json"
$keyVaultDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/KeyVault/$kvTemplateFileName.json --parameters keyVaultName=$keyVaultName objectId=$objectId"

$logWorkspaceShowCommand = "az monitor log-analytics workspace show -g $resourceGroup -n $logWorkspaceName --query='id'"
$logWorkspaceDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/Monitoring/$lwTemplateFileName.json --parameters workspaceName=$logWorkspaceName location=$location resourcePermissions=true"

$spShowCommand = "az ad sp show --id http://$azcSPDisplayName --query 'appId'"
$spCreateCommand = "az ad sp create-for-rbac --skip-assignment --name $azcSPDisplayName --query '{appId:appId, secret:password}' -o json"

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

$acrInfo = Invoke-Expression -Command $acrShowCommand
if (!$acrInfo)
{
    
    Invoke-Expression -Command $acrDeployCommand
    $acrInfo = Invoke-Expression -Command $acrShowCommand
    Write-Host $acrInfo

}

$keyVaultInfo = Invoke-Expression -Command $keyVaultShowCommand
if (!$keyVaultInfo)
{

    Invoke-Expression -Command $keyVaultDeployCommand
    $keyVaultInfo = Invoke-Expression -Command $keyVaultShowCommand
    Write-Host $keyVaultInfo

}

$logWorkspaceInfo = Invoke-Expression -Command $logWorkspaceShowCommand
if (!$logWorkspaceInfo)
{

    Invoke-Expression -Command $logWorkspaceDeployCommand
    $logWorkspaceInfo = Invoke-Expression -Command $logWorkspaceShowCommand
    Write-Host $logWorkspaceInfo

}

$containerSolutionDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/Monitoring/$containerTemplateFileName.json --parameters workspaceResourceId=$logWorkspaceInfo workspaceRegion=$location"
Invoke-Expression -Command $containerSolutionDeployCommand

$azcSP = Invoke-Expression -Command $spShowCommand
if (!$azcSP)
{
    $azcSP = Invoke-Expression -Command $spCreateCommand
    if (!$azcSP)
    {

        Write-Host "Error creating Service Principal for AKS"
        return;

    }

    $appId = ($azcSP | ConvertFrom-Json).appId
    $secret = ($azcSP | ConvertFrom-Json).secret

    $kvShowAppIdCommand = "az keyvault secret show -n $azcSPIdName --vault-name $keyVaultName --query 'id' -o json"
    $kvAppIdInfo = Invoke-Expression -Command $kvShowAppIdCommand
    if (!$kvAppIdInfo)
    {
        $kvSetAppIdCommand = "az keyvault secret set --vault-name $keyVaultName --name $azcSPIdName --value $appId"
        Invoke-Expression -Command $kvSetAppIdCommand
    }

    $kvShowSecretCommand = "az keyvault secret show -n $azcSPSecretName --vault-name $keyVaultName --query 'id' -o json"
    $kvSecretInfo = Invoke-Expression -Command $kvShowSecretCommand
    if (!$kvSecretInfo)
    {
        $kvSetSecretCommand = "az keyvault secret set --vault-name $keyVaultName --name $azcSPSecretName --value $secret"
        Invoke-Expression -Command $kvSetSecretCommand
    }

    $acrRoleCommand = "az role assignment create --assignee $appId --role 'AcrPush' --scope $acrInfo"
    Invoke-Expression -Command $acrRoleCommand

    $resourceGroupRoleCommand = "az role assignment create --assignee $appId --role 'Owner' --scope '/subscriptions/$subscriptionId/resourceGroups/$resourceGroup'"
    Invoke-Expression -Command $resourceGroupRoleCommand

}

$workspaceIdCommand = "az monitor log-analytics workspace list --resource-group $resourceGroup --query '[0].customerId' -o json"
$workspaceId = Invoke-Expression -Command $workspaceIdCommand

$kvShowWsIdCommand = "az keyvault secret show -n $wsIdName --vault-name $keyVaultName --query 'id' -o json"
$kvWsIdInfo = Invoke-Expression -Command $kvShowWsIdCommand
if (!$kvWsIdInfo)
{
    $kvSetWorkspaceIdCommand = "az keyvault secret set --vault-name $keyVaultName --name $wsIdName --value $workspaceId"
    Invoke-Expression -Command $kvSetWorkspaceIdCommand
}

$workspaceSecretCommand = "az monitor log-analytics workspace get-shared-keys --resource-group $resourceGroup --workspace-name $logWorkspaceName --query 'primarySharedKey' -o json"
$workspaceSecret = Invoke-Expression -Command $workspaceSecretCommand

$kvShowWsSecretCommand = "az keyvault secret show -n $wsSecretName --vault-name $keyVaultName --query 'id' -o json"
$kvWsSecretInfo = Invoke-Expression -Command $kvShowWsSecretCommand
if (!$kvWsSecretInfo)
{
    $kvSetWorkspaceSecretCommand = "az keyvault secret set --vault-name $keyVaultName --name $wsSecretName --value $workspaceSecret"
    Invoke-Expression -Command $kvSetWorkspaceSecretCommand
}

Write-Host "------------Pre-Config----------"
