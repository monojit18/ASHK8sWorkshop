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
      [Parameter(Mandatory=$false)] [string] $projectName = "ash-workshop",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $clusterInternalName = "<cluster_internal_name>",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "ash-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<base_Folder_Path>") # Till Deployments

$wsIdName = $clusterName + "-ws-id"
$wsSecretName = $clusterName + "-ws-secret"
$yamlFilePath = "$baseFolderPath/YAMLs"
$ingControllerName = $projectName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$monitoringNSName = "monitoring"

$kvShowWSIdCommand = "az keyvault secret show -n $wsIdName --vault-name $keyVaultName --query 'value' -o tsv"
$wsId = Invoke-Expression -Command $kvShowWSIdCommand
if (!$wsId)
{
      Write-Host "Error fetching Monitoring Id"
      return;
}

$kvShowWSSecretCommand = "az keyvault secret show -n $wsSecretName --vault-name $keyVaultName --query 'value' -o tsv"
$wsSecret = Invoke-Expression -Command $kvShowWSSecretCommand
if (!$wsSecret)
{
      Write-Host "Error fetching Monitoring Secret"
      return;
}

# Create Monitoring Namespace
$monitoringNSCommand = "kubectl create namespace $monitoringNSName"
Invoke-Expression -Command $monitoringNSCommand

# Install Monitoring using Helm
$repoAddCommand = "helm repo add microsoft https://microsoft.github.io/charts/repo"
Invoke-Expression -Command $repoAddCommand

$repoUpdateCommand = "helm repo update"
Invoke-Expression -Command $repoUpdateCommand

$installCommand = "helm install azmoncon -n monitoring --set omsagent.secret.wsid=$wsId,omsagent.secret.key=$wsSecret,omsagent.env.clusterName=$clusterInternalName, microsoft/azuremonitor-containers"
Invoke-Expression -Command $installCommand

# Create nginx Namespace
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$repoAddCommand = "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
Invoke-Expression -Command $repoAddCommand

$repoUpdateCommand = "helm repo update"
Invoke-Expression -Command $repoUpdateCommand

$nginxILBCommand = "helm install $ingControllerName ingress-nginx/ingress-nginx --namespace $ingControllerNSName -f $yamlFilePath/Common/$ingControllerFileName.yaml"
Invoke-Expression -Command $nginxILBCommand

Write-Host "-----------Post-Config------------"
