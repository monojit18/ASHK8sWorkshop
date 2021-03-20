# Boot-up Your Own Kubernetes Engine  -                with AKS-Engine and Azure Stack Hub



## Prelude

### AKS-Engine - Units of Kubernetes on Azure!

This is how AKS-Engine is described in a nutshell - one that provides ingredients to build to your own vanilla K8s cluster on Azure VMs.

This is also forms the foundation for Microsoft's flagship product for managed Kubernetes on Azure cloud - a.k.a *AKS*. Although there are more popular and community supported open source tools available to have a vanilla cluster anywhere - e.g. *Cluster API Provider* a.k.a *CAPZ*. And as it seems this is going to be the de-facto tool for cluster deployment on any cloud or on-prem.

While the above options are all good for *Azure Public Cloud* scenarios, how to meet the customer requirements on deploying K8s on their data centres? While customers can use *CAPZ* or the most popular, standard tools like *kubeadm* can be used to spin-off a cluster; bit the customers want to ue that cluster with many other services like *Cognitive*, *Storage*, *Serverless*, *App Services* etc.

The service designated from Azure for running PaaS services on-prem is *Azure Stack Hub* a.k.a *ASH*. Microsoft is adding more critical services one-by-one into ASH to support the on-prem need for PaaS from customers. So. to tie that on-prem PaaS story with Containers - the only option e have now is the AKS-Engine - which provides similar set of templates for Stack Hub as for the public cloud....and vanilla K8s cluster can be spinned-off easily and quickly on Stack Hub.

Without much prelude, let us get into some action.

But K8s cluster is not the only thing that user(s) are going to create; rather the ancillary services around the cluster helping build the entire architecture is most important, painfully redundant and difficult to manage in long terms - more so when you think of the Operations team or Infrastructure management team - who might need to do this for multiple cluster to be managed and many applications to be deployed!

Hence a disciplined, streamlined and automated approach is needed so that end to end architecture becomes robust, resilient and easily manageable.

The purpose of this workshop would be to:

- Use Kubernetes as the tool for orchestration of micro-services
- Build micro-services of varying nature and tech-stack
- Build an automated pipeline and workflow for creating Infrastructure for the deploying micro-services - *3-Step Approach*
- Use AKS-engine templates for creating the Core K8s infrastructure
- Use ARM templates to deploy other ancillary Azure resources
- Extend the pipeline to automate deployment of micro-services
- Use the built-in features of K8s for monitoring, security and upgrades
- Define Resource Quota and appropriate Storage for micro-services
- Integrating with Azure AD and define RBAC for the cluster and its sub-components

### Pre-requisites, Assumptions

- Knowledge on Containers and MicroServices - *L300+*
- How to build docker image and create containers from it
- Knowledge on K8s  - *L300+*
- Some knowledge on Azure tools & services viz. *Azure CLI, KeyVault, VNET* etc. would help
- Apps and Micro-Services would be used interchangeably i.e. both are treated as same in this context



## Reference Architecture

![ASH-Ref-Architecture-v1.0-Stack-Hub-Ref-Arch](/Users/monojitd/Materials/Projects/AKSProjects/ASHK8sWorkshop/Assets/ASH-Ref-Architecture-v1.0-Stack-Hub-Ref-Arch.png)



## Action

Let us now get into some action with all *Plans* in-place!

As we had mentioned, it would be a 3-step approach to create the cluster. We would first do this with scripts from command line and then would do the same using Azure DevOps. Once the cluster is ready, we can start deploying applications onto it. Let us set the ball rolling...

Before getting into actual action, couple of minutes to understand the folder structure that we would be following (*most important*). 

###### [Deployments](#step-by-step)

- **Certs** - Contains all certificates needed; in this case basically the SSL certificate for Ingress controller

  (*Note*: *This folder is not checked into the repo; please create this folder on your local system and necessary certificates*)

- **Azure-CLI** - Contains all necessary files for azure cli scripts to be used for deployment. For folks want to do in Terraform way should create a similar folder and the appropriate files inside

  - **Setup** - Contains all the scripts to be used in this process

  (*Ref*: *<>*)

  - **Templates** - The key folder which contains all ARM templates and corresponding PowerShell scripts to deploy them. This ensures a completely decoupled approach for deployment; all ancillary components can be deployed outside the cluster process at any point of time!

    (*Ref*: *<>*)

- **YAMLs** - Contains all YAML files needed post creation of cluster - Post Provisioning stage where created cluster is configured by Cluster Admins

  (*Ref*:<>)

  - **ClusterAdmin** - Scripts for Cluster Admin functionalities

    (*Ref*: *<>*)

  - **Common** - Scripts used across different namespaces - e.g. *nginx ingress* configuration file

    (*Ref*: *<>*)

  - **Ingress** - Scripts for Ingress creation for the DEV namespace

    (*Ref*: *<>*)

  - **RBAC** - Scripts for RBAC definition for entire cluster as well as namespaces resources

    (*Ref*: *<>*)



## Anatomy of the Approach

![ASH-Ref-Architecture-v1.0-ASH-Anatomy](/Users/monojitd/Materials/Projects/AKSProjects/ASHK8sWorkshop/Assets/ASH-Ref-Architecture-v1.0-ASH-Anatomy.png)



### Step-By-Step

1. Connect to Azure Stack Hub through VPN *(credentials should be provided while opted*)

2. Connect to Azure Stack Hub portal - format should be like - **portal.<region>.<FQDN>**

3. Create a *Management Resource Group*, say, **ash-mgmt-rg**

4. Create VNet and SubNet for Jump Server VM. The one used for the workshop was -

   - VNET - **11.0.0.0/16**
   - Subnet - **11.0.0.0/27**

5. Create a Jump Server VM - preferred is Windows VM so that all visualisation tools like **Lens** etc. can be used to view the cluster status at runtime. The one used for this workshop was - 

   - OS - **Windows Server 2019 DC - v1809**
   - Size  - **Standard DS2 v2 (2 vcpus, 7 GiB memory)**

6. RDP to the windows VM

7. Install following tools for creation and management of the cluster and its associated resources

   1. **Chocolatey**

      ```bash
      # Follow this link and install Chocolatey latest
      https://chocolatey.org/install
      ```

   2. **Azure CLI**

      ```bash
      # Follow this link and install Azure CLI latest
      https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli
      ```

   3. **Kubectl**

      ```bash
      choco install kubernetes-cli
      
      # Otherwise, follow the various options at -
      https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/ 
      ```

   4. **Helm**

      ```
      choco install kubernetes-helm
      ```

   5. **PowerShell Core**

      ```bash
      # Follow this link and install PowerShell Core for Windows
      https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7.1
      
      # Install Az module for communicating to Azure over Az cmdlet
      Install-Module -Name Az -AllowClobber
      ```

   6. **Lens**

      ```bash
      # Follow this link and install Lens for Windows
      https://k8slens.dev/
      ```

   7. (Optional) **Visual Studio Code**

      ```bash
      # Follow this link and install Visual Studio Code
      # This is for better management of scripts and commands
      https://code.visualstudio.com/docs/setup/windows
      ```

   8. (*Optional*) **Docker**

      ```bash
      # Follow this link and install Docker Desktop latest for Windows
      https://docs.docker.com/docker-for-windows/install/
      
      # Install this only if you want to play with Docker images locally
      # This workshop will use a different techniqe so installation of Docker is not needed
      ```

8. Clone the repo - (<>) into your local folder somewhere on the VM. Open and browse the files in VS Code editor and has a quick look; check the folder structure as described in the section [above](#deployments)

9. The Jump server is now ready to be used for subsequent deployments

10. Open PowerShell Core on the VM. Set cloud option to *Azure Public Cloud*

    ```bash
    az cloud set -n "AzureCloud"
    ```

11. Login to Azure Tenant

    ```bash
    az login --tenant <tenant_id>
    
    # This can be a userid based login or a Service Princiapl based login. In either case the logged in credential should have enough privilidges to perform all resource creation
    
    # Ideally an Application Administrator Role shoud be enough to run through all the steps
    ```

12. Prepare *Azure Public Cloud*

    - Run ***Deployments/Azure-CLI/Setup/azc-cluster-preconfig.ps1***
      - ***Example***

        ```bash
        ./azc-cluster-preconfig.ps1 --resourceGroup "azc-workshop-rg" --location "eastus" --clusterName "ash-workshop-cluster" --acrName "azcashacr" --keyVaultName "azc-workshop-kv" -logWorkspaceName "azc-workshop-lw" --acrTemplateFileName "azc-acr-deploy" --kvTemplateFileName "azc-keyvault-deploy" --lwTemplateFileName "azc-lw-deploy" --containerTemplateFileName "containerSolution" --subscriptionId "<subscription_Id>" --objectId "<object_Id>" --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***:

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Following Values should **<u>NOT</u>** be changed. These are file names of template files to be used by the script(s) and filenames have already been set. Unless you change those filenames in your local repo, no need to play around with those name!!

          - **acrTemplateFileName**
          - **kvTemplateFileName**
          - **lwTemplateFileName**
          - **containerTemplateFileName**

        - Provide values for following 3 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

          - **objectId** - Azure AD objectId of the logged-in user/service principal; this can be found on the -

            ***Azure AD page -> Select User or Service Principal (as the case may be) -> Look at Overview page***

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

        - This scripts deploys following resources on Azure Public Cloud

          - **Azure Container Registry (ACR)** - K8s cluster on Stack Hub would pull images from here 
          - **Azure KeyVault (KV)** - used for storing Service Principals in Azure Public Cloud to be used later by Stack Hub while creating the cluster
          - **Azure Log Analytics** - Monitoring workspace; K8s cluster on Stack Hub would store all Monitoring data here
          - **Azure AD Service Principal** - This will be used by K8s cluster on Stack Hub while creating the cluster

    - Set cloud option to *Azure Stack User*

      ```bash
      az cloud set -n "AzureStackUser"
      ```

    - Update Cloud Profile for Hybrid Cloud

      ```bash
      az cloud update --profile 2019-03-01-hybrid
      ```

    - Login to Azure Tenant

      ```bash
      az login --tenant <tenant_id>
      
      # This can be a userid based login or a Service Princiapl based login. In either case the logged in credential should have enough privilidges to perform all resource creation
      
      # Ideally an Application Administrator Role shoud be enough to run through all the steps
      ```

    - Prepare *Azure Stack Cloud*

      - Run ***Deployments/Azure-CLI/Setup/ash-cluster-preconfig.ps1***

        - ***Example***

          ```bash
          ./ash-cluster-preconfig.ps1  --resourceGroup "ash-workshop-rg" --bastionResourceGroup "Inshorts-POC2" --location "azs001" --clusterName "ash-workshop-cluster" --keyVaultName "ash-workshop-kv" --bastionVNetName "master-hub-vnet" --ashVNetName "ash-workshop-vnet" --ashVNetPrefix "12.0.0.0/16" --ashSubnetName "ash-workshop-subnet" --ashSubnetPrefix "12.0.0.0/21" --kvTemplateFileName "ash-keyvault-deploy" --networkTemplateFileName "ash-network-deploy" --subscriptionId "<subscription_Id>" --objectId "<object_Id>" --baseFolderPath "<base_Folder_Path>"
          ```

        - **Note**

          - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

          - Provide values for following 3 variables with are displayed as place holders

            - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

            - **objectId** - Azure AD objectId of the logged-in user/service principal; this can be found on the -

              ***Azure AD page -> Select User or Service Principal (as the case may be) -> Look at Overview page***

            - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

          - This scripts deploys following resources on Azure Public Cloud

            - 

    

### Step 1 - PreConfig (*Pre-Provisioning*)

- **Azure Public Cloud**

  - Set cloud option to Azure CLoud

    ```bash
    az cloud set -n "AzureCloud"
    ```

  - Login to your tenant

    ```bash
    az login --tenant <tenant_id>
    
    # This can be a userid based login or a Service Princiapl based login. In either case the logged in credential should have neough privilidges to perform all resource creation
    # Ideally an Application Administrator Role shoud be enough to run through all the steps
    ```

  - Run ***Deployments/Azure-CLI/Setup/azc-cluster-preconfig.ps1***

    ```
    ./azc-cluster-preconfig.ps1
    ```

    - Anatomy of the script

      - **Parameters**

      ```bash
      # resource group t hold all resouces reated in Azure public Clpud
      [string] $resourceGroup
      
       # location of deployment
      [string] $location
      [string] $clusterName # K8s cluster name
      [string] $acrName # Azure Container Registry name; K8s cluster would pull images from here
      [string] $keyVaultName # KeyVault name - used for storing Service Principals in Azure Public Cloud 
      # To be used later by Stack Hub while creating the cluster
      [string] $logWorkspaceName
      [string] $acrTemplateFileName
      [string] $kvTemplateFileName
      [string] $lwTemplateFileName
      [string] $containerTemplateFileName
      [string] $subscriptionId # <subscription_Id> of the loggd-in user/service princiapl
      [string] $objectId # Azure AD objectId of the logged-in user/service princiapl
      [string] $baseFolderPath # This is the path of the Deployments folder in the source repo
      ```

      

