param([Parameter(Mandatory=$false)] [string] $resourceGroup = "ash-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $projectName = "ash-workshop",
      [Parameter(Mandatory=$false)] [string] $clusterName = "ash-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "ash-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $ashVNetName = "ash-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "C:\Users\azureuser\Developments\Projects\ASHK8sWorkshop\Deployments")

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

$installCommand = "helm install azmoncon -n monitoring --set omsagent.secret.wsid=$wsId,omsagent.secret.key=$wsSecret,omsagent.env.clusterName=ash-workshop-cluster-60423007, microsoft/azuremonitor-containers"
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
