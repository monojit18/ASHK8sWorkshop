# Start-up Kubernetes Engine on Azure Stack Hub - Step-By-Step



## Prelude

### Azure Stack Hub

**As per Microsoft docs** - *Azure Stack Hub* is an extension of Azure that provides a way to run apps in an on-premises environment and deliver Azure services in your datacenter. With a consistent cloud platform, organisations can confidently make technology decisions based on business requirements, rather than business decisions based on technology limitations.

### AKS-Engine

### Units of Kubernetes on Azure!

This is how AKS-Engine is described in a nutshell - one that provides ingredients to build to your own vanilla K8s cluster on Azure VMs.

This is also forms the foundation for Microsoft's flagship product for managed Kubernetes on Azure cloud - a.k.a *AKS*. Although there are more popular and community supported open source tools available to have a vanilla cluster anywhere - e.g. *Cluster API Provider* a.k.a *CAPZ*. And as it seems this is going to be the de-facto tool for cluster deployment on any cloud or on-prem.

While the above options are all good for *Azure Public Cloud* scenarios, how to meet the customer requirements on deploying K8s on their data centres? While customers can use *CAPZ* or the most popular, standard tools like ***kubeadm*** can be used to spin-off a cluster; but the customers want to use that cluster with many other services like *Cognitive*, *Storage*, *Serverless*, *App Services* etc.

The service designated from Azure for running PaaS services on-prem is *Azure Stack Hub* a.k.a *ASH*. Microsoft is adding more critical services one-by-one into ASH to support the on-prem need for PaaS from customers. So. to tie that on-prem PaaS story with Containers - the only option we have now is the **AKS-Engine** - which provides similar set of templates for Stack Hub as for the public cloud....and vanilla K8s cluster can be spinned-off easily and quickly on Stack Hub.

Without much prelude, let us get into some action.

But K8s cluster is not the only thing that user(s) are going to create; rather the ancillary services around the cluster helping build the entire architecture is most important, painfully redundant and difficult to manage in long terms - more so when you think of the Operations team or Infrastructure management team - who might need to do this for multiple cluster to be managed and many applications to be deployed!

Hence a *Disciplined, Streamlined* and *Automated* approach is needed so that end to end architecture becomes *Robust*, *Resilient* and easily *Manageable*.

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



## Action

Let us now get into some action with all *Plans* in-place!

As we had mentioned, it would be a 3-step approach to create the cluster. We would first do this with scripts from command line and then would do the same using Azure DevOps. Once the cluster is ready, we can start deploying applications onto it. Let us set the ball rolling...

Before getting into actual action, couple of minutes to understand the folder structure that we would be following (*most important*). 

### Deployments

- **Certs** - Contains all certificates needed; in this case basically the SSL certificate for Ingress controller

  (*Note*: *This folder is not checked into the repo; please create this folder on your local system and necessary certificates*)

- **Azure-CLI** - Contains all necessary files for azure cli scripts to be used for deployment. For folks want to do in Terraform way should create a similar folder and the appropriate files inside

  - **Setup** - Contains all the scripts to be used in this process

    (***Ref***: *Deployments/Azure-CLI/Setup*)

  - **Templates** - The key folder which contains all ARM templates and corresponding PowerShell scripts to deploy them. This ensures a completely decoupled approach for deployment; all ancillary components can be deployed outside the cluster process at any point of time!

    (***Ref***: ***Deployments/Azure-CLI/Templates***)

- **YAMLs** - Contains all YAML files needed post creation of cluster - Post Provisioning stage where created cluster is configured by Cluster Admins

  (***Ref***: ***Deployments/YAMLs***)

  - **ClusterAdmin** - Scripts for Cluster Admin functionalities

    (*Ref*: ***Deployments/YAMLs/ClusterAdmin***)

  - **Common** - Scripts used across different namespaces - e.g. *nginx ingress* configuration file

    (*Ref*: ***Deployments/YAMLs/Common***)

  - **Ingress** - Scripts for Ingress creation for the DEV namespace

    (*Ref*: ***Deployments/YAMLs/DEV/Ingress***)

  - **Monitoring** - Scripts for Container Monitoring for entire cluster. For this workshop it includes the Prometheus config map which would allow Prometheus to scrape data from specific Pods, Services

    (*Ref*: ***Deployments/YAMLs/DEV/Monitoring***)
    
  - **Netpol** - Scripts for defining network policies between Pods, Services as well as outbound from Pods
  
    (*Ref*: ***Deployments/YAMLs/DEV/Netpol***)
  
  - **RBAC** - Scripts for defining RBAC between various resources within K8s cluster
  
    (*Ref*: ***Deployments/YAMLs/DEV/RBAC***)



## Anatomy of the Approach



### Step-By-Step

1. **Connect** to Azure Stack Hub through VPN *(credentials should have been provided while opted*)

2. **Connect** to Azure Stack Hub portal - format should be like - **portal.<region>.<FQDN>**

3. **Create** a *Management Resource Group*, say, **ash-mgmt-rg**

4. **Create** VNet and SubNet for Jump Server VM. The one used for the workshop was -

   - VNET - **11.0.0.0/16**
   - Subnet - **11.0.0.0/27**

5. **Create** a Jump Server VM - preferred is Windows VM so that all visualisation tools like **Lens** etc. can be used to view the cluster status at runtime. The one used for this workshop was - 

   - OS - **Windows Server 2019 DC - v1809**
   - Size  - **Standard DS2 v2 (2 vcpus, 7 GiB memory)**

6. **RDP** to the windows VM

7. **Install** following tools for creation and management of the cluster and its associated resources

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

   6. **Lens** - *For monitoring Cluster resources*

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

8. **Docker Private Registry**

   - User(s) might want to use *Private Docker registry* to store their scanned, cleaned images and distribute them through the K8s cluster
   - While *Azure Container Registry* is a natural choice, but that means it is an outbound call to *Azure Public Cloud* from the K8s cluster on *Azure Stack Cloud*
   - Preparing a *Docker Registry* is easy - https://docs.docker.com/registry/deploying/
   - This can be setup on the same Jump Server Or on any other machine

9. **Clone** the repo - (<>) into your local folder somewhere on the VM. Open and browse the files in VS Code editor and have a quick look; check the folder structure as described in the section [above](#deployments)

10. The **Jump Server** is now ready to be used for subsequent deployments

11. **Open** PowerShell Core on the VM. Set cloud option to *Azure Public Cloud*

    ```bash
    az cloud set -n "AzureCloud"
    ```

12. **Login** to Azure Tenant

    ```bash
    az login --tenant <tenant_id>
    
    # This can be a userid based login or a Service Princiapl based login. In either case the logged in credential should have enough privilidges to perform all resource creation
    
    # Ideally an Application Administrator Role shoud be enough to run through all the steps
    ```

13. **Prepare** *Azure Public Cloud*

    - Run ***Deployments/Azure-CLI/Setup/azc-cluster-preconfig.ps1***
      - ***Example***

        ```bash
        ./azc-cluster-preconfig.ps1 --resourceGroup "azc-workshop-rg" --location "eastus" --clusterName "ash-workshop-cluster" --acrName "azcashacr" --keyVaultName "azc-workshop-kv" -logWorkspaceName "azc-workshop-lw" --acrTemplateFileName "azc-acr-deploy" --kvTemplateFileName "azc-keyvault-deploy" --lwTemplateFileName "azc-lw-deploy" --containerTemplateFileName "containerSolution" --subscriptionId "<subscription_Id>" --objectId "<object_Id>" --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***

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

            This Log Analytics WorkspaceId and WorkspaceSecret are added into the KeyVault - **azc-workshop-kv**; the names would be like -

            1. **<cluster_name>-ws-id**
            2. **<cluster_name>-ws-secret**

          - **Azure AD Service Principal** - This will be used by K8s cluster on Stack Hub while creating the cluster

            This Service Principal is added into the KeyVault - **azc-workshop-kv**; the names would be like -

            1. **<cluster_name>-sp-id** 
            2. **<cluster_name>-sp-secret**

            

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

14. **Prepare** *Azure Stack Cloud*

    - Run ***Deployments/Azure-CLI/Setup/ash-cluster-preconfig.ps1***

      - ***Example***

        ```bash
        ./ash-cluster-preconfig.ps1  --resourceGroup "ash-workshop-rg" --bastionResourceGroup "ash-mgmt-rg" --location "azs001" --clusterName "ash-workshop-cluster" --keyVaultName "ash-workshop-kv" --bastionVNetName "master-hub-vnet" --ashVNetName "ash-workshop-vnet" --ashVNetPrefix "12.0.0.0/16" --ashSubnetName "ash-workshop-subnet" --ashSubnetPrefix "12.0.0.0/21" --kvTemplateFileName "ash-keyvault-deploy" --networkTemplateFileName "ash-network-deploy" --subscriptionId "<subscription_Id>" --objectId "<object_Id>" --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following 3 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

          - **objectId** - Azure AD objectId of the logged-in user/service principal; this can be found on the -

            ***Azure AD page -> Select User or Service Principal (as the case may be) -> Look at Overview page***

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

        - Following Values should **<u>NOT</u>** be changed. These are the file names of template files to be used by the script(s) and filenames have already been set. Unless you change those filenames in your local repo, no need to play around with those name!!

          - **kvTemplateFileName**
          - **networkTemplateFileName**

        - This scripts deploys following resources on *Azure Stack Cloud*

          - **VNet** for K8s cluster on Stack Hub - **ashVNetName**

          - **Subnet** to host K8s cluster on Stack Hub - **ashSubnetName**

          - **Peering** of K8s VNet (i.e. **ashVNetName**) with the Jump Server VNet (i.e. **master-hub-vnet**)

            This will ensure that when the cluster is created, the Jump Server would be able to reach to the cluster and manage it. The K8s cluster to be created would be a ***Private Cluster***

          - **KeyVault** to store various Secrets on Stack Hub - e.g.

            - **Service Principal** from Azure Public Cloud
            - **Log Analytics** Resource Id and Secret (***to be discussed later***)

15. **Setup** K8s cluster on **Azure Stack Cloud**

    - Prepare for **RBAC**

      - **K8s** cluster on Stack Hub would need few parameters from Azure AD for RBAC
      - Follow the link to setup **Azure AD** in Azure Public Cloud - https://github.com/Azure/aks-engine/blob/master/docs/topics/aad.md
      - The 4 major parameters needed for subsequent steps -
        - **clientAppID** - Application ID of the Client App as described above
        - **serverAppID** - Application ID of the Server App as described above
        - **tenantID** - The Tenant ID of the Azure AD where the above two applications are created. This can be any valid tenant
        - **adminGroupID** - The Group ID of the Cluster Admin Group created in the above tenant. This group would be given the Cluster Admin privileges after the creation of the K8s cluster

    - Prepare Configuration values for K8s Cluster

      - Browse to ***Deployments/Azure-CLI/Templates/AKSEngine/ash-config.json***
      - This is the Config file used by AKS-engine to deploy new K8s cluster
      - Default values are all set; rest will be supplied at runtime by the following script - **ash-cluster-setup.ps1**

    - Install **AKS-Engine** for Stack Hub

      - Follow this link to choose appropriate version to be installed - https://github.com/Azure/aks-engine/blob/master/docs/topics/azure-stack.md#aks-engine-versions
      - This workshop uses - **v0.55.4** - https://github.com/Azure/aks-engine/releases/tag/v0.55.4
      - Once installed, you are ready to run the following script to create the K8s cluster

    - Run ***Deployments/Azure-CLI/Setup/ash-cluster-setup.ps1***

      - ***Example***

        ```bash
        ./ash-cluster-setup.ps1 --resourceGroup "ash-workshop-rg" --location "azs001" --clusterName "ash-workshop-cluster" --keyVaultName "ash-workshop-kv" --ashVNetName "ash-workshop-vnet" --ashSubnetName "ash-workshop-subnet" --clientAppID "<client_AppID>" --serverAppID  "<server_AppID>" --adminGroupID  "<cluster_admin_groupId>" --tenantID  "<cluster_admin_tenantId>" --subscriptionId "<subscription_Id>" --baseFolderPath "<base_Folder_Path>"
        ```

        - Provide values for the Azure AD placeholder values as obtained from above
          - **clientAppID**
          - **serverAppID**
          - **tenantID**
          - **adminGroupID**
        - Add **Service Principal** secrets into **KeyVault** on Stack Hub
          - Goto KeyVault created in Azure Public Cloud - **azc-workshop-kv**
          - Copy the Service Principal ID and Secret stored there by the PreConfig script as describe above
          - Add these two values to the KeVault created on Stack Hub - **ash-workshop-kv**
        - Provide values for following 3 variables with are displayed as place holders
          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*
          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

16. **Connect** to the Cluster

    - *KubeConfig* is the file to organise your *clusters, users, namespaces* and *authentication* mechanisms

    - Every machine accessing the K8s cluster, a config file is created at the .kube folder location under Home directory

    - In case of AKS-Engine, once the cluster is deployed first time, the generated kubeconfig file would be created at -

      ***Deployments/Azure-CLI/Templates/AKSEngine/Output/ClusterInfo/kubeconfig*** in the Jump Server VM

    - From this workshop, we have created the Jump Server which is a Windows 2019 DC VM. So, we should go to the User's Home directory and create a .**kube**

    - Copy this file to .**kube** folder just created above

    - Create System Environment variable called *KUBECONFIG* with the path of the file under .**kube** folder

    - Type in the following command to see if cluster creation ok or not

      ```bash
      kubectl get nodes
      ```

    - This should list down all the nodes in the cluster - for this workshop - it would come up with *3 Master Nodes* and *3 Worker Nodes*. This ensures that cluster is all ok and healthy!

17. **Configure** K8s cluster post creation

    - The K8s cluster is still with Cluster Admin group members

    - Run ***Deployments/Azure-CLI/Setup/ash-cluster-postconfig.ps1***

      - ***Example***

        ```bash
        ./ash-cluster-postconfig.ps1 --resourceGroup "ash-workshop-rg" --projectName "ash-workshop" --clusterName "ash-workshop-cluster" --keyVaultName "ash-workshop-kv"
        --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following variable(s) which are displayed as place holders

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

        - Following variables need some explanation

          - **projectName** - This is used internally by the script to define names for various resources that are to be deployed on the K8s cluster
          - **clusterInternalName** - This is the name with which the cluster is created - basically **clusterName-<randomId>**. This name can be found at the **KubeConfig** file.

        - This scripts deploys following resources on K8s cluster

          - **ContainerInsights** Solution on the Log Analytics workspace created in *Azure Public Cloud*. Please note that Log Analytics workspace does not have any Solution deployed by default and hence no monitoring would happen; unless the **ContainerInsights** solution is explicitly deployed

          - **Ingress Controller** - **Nginx** is used as *Ingress* for this workshop; but any other *Ingress controller* can be used. This is deployed as a public Load Balancer. The Public IP here is actually Enterprise public IP i.e. an IP from within the on-premise network of the Stack Hub User; but NOT a private IP from the Virtual Network address space.

            Users can decide deploy Nginx as Internal Load Balancer i.e. with a Private IP. But in that case a proper L7 External Load Balancer would be needed which would connect to the Nginx Ingress as backend pool.

            In the absence of such L7 ELB like Application gateway on Azure Stack Hub, some other 3rd party services can be used e.g. F5, which are now available on Stack Hub

18. **Add** more Node pools to the Cluster

    - Users can add more Node pools to the existing with different Node sizes than the initial ones created along with the cluster

    - Define a config file for Node pool e.g, ***Deployments/Azure-CLI/Templates/AKSEngine/ash-nodepool.json***

    - A sample one is already created. Browse the file and change as per the requirement

    - Run ***Deployments/Azure-CLI/Setup/ash-cluster-nodepool.ps1***

      - ***Example***

        ```bash
        ./ash-cluster-nodepool.ps1 --mode "add" --resourceGroup "ash-workshop-rg"
        --location "<stack_hub_location>" --clusterName "ash-workshop-cluster" --keyVaultName "ash-workshop-kv" --subscriptionId "<subscription_Id>" --nodePoolConfigFileName "ash-nodepool" --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following 2 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

        - Following Values should **<u>NOT</u>** be changed. These are the file names of template files to be used by the script(s) and filenames have already been set. Unless you change those filenames in your local repo, no need to play around with those name!!

          - **nodePoolConfigFileName**

        - This scripts deploys following resources on *Azure Stack Cloud*

          - New Node pool - in this workshop it is named as - **ashiotpool**
          - Node pool count - **3** - in this workshop

19. **Scale-Out** existing Node pools

    - Run ***Deployments/Azure-CLI/Setup/ash-cluster-nodepool.ps1***

      - ***Example***

        ```bash
        ./ash-cluster-nodepool.ps1 --mode "scale" --resourceGroup "ash-workshop-rg"
        --location "<stack_hub_location>" --clusterName "ash-workshop-cluster" --keyVaultName "ash-workshop-kv" --subscriptionId "<subscription_Id>" --nodePoolConfigFileName "ash-nodepool" --nodepoolName "ashapipool" --newNodeCount 3 --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following 2 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

        - Following Values should **<u>NOT</u>** be changed. These are the file names of template files to be used by the script(s) and filenames have already been set. Unless you change those filenames in your local repo, no need to play around with those name!!

          - **nodePoolConfigFileName**

        - This scripts deploys following resources on *Azure Stack Cloud*

          - Scale and existing Node pool - in this workshop it is named as - **ashapipool**
          - Node pool count - **3** - in this workshop

20. **Scale-In** existing Node pools

    - **Scale_In** is actually not a deployment; behind the scene, AKS-engine deletes Nodes and adjusts the Node pool count to the desired level. Although this option is Not recommended and suggestion is to rely on **Cluster AutoScaler** (a.k.a *Node AutoScaler*) - but this is not available now in *Azure Stack Hub*

    - Run ***Deployments/Azure-CLI/Setup/ash-cluster-nodepool.ps1***

      - ***Example***

        ```bash
        ./ash-cluster-nodepool.ps1 --mode "scale" --resourceGroup "ash-workshop-rg"
        --location "<stack_hub_location>" --clusterName "ash-workshop-cluster" --keyVaultName "ash-workshop-kv" --subscriptionId "<subscription_Id>" --nodePoolConfigFileName "ash-nodepool" --nodepoolName "ashapipool" --newNodeCount 2 --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following 2 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../ASHK8sWorkshop/Deployments**

        - Following Values should **<u>NOT</u>** be changed. These are the file names of template files to be used by the script(s) and filenames have already been set. Unless you change those filenames in your local repo, no need to play around with those name!!

          - **nodePoolConfigFileName**

        - This scripts deploys following resources on *Azure Stack Cloud*

          - Scale and existing Node pool - in this workshop it is named as - **ashapipool**
          - Node pool count - **2** - in this workshop

21. **Deploy** Ingress object

    - **Ingress** objects are used for Routing to appropriate services within the cluster

      *Ref*: ***Deployments/YAMLs/DEV/Ingress/ash-ingress.yaml***

      ```yaml
      apiVersion: networking.k8s.io/v1beta1
      kind: Ingress
      metadata:
        name: ash-workshop-ingress
        namespace: ash-workshop-dev
        annotations:
          kubernetes.io/ingress.class: nginx
          nginx.ingress.kubernetes.io/rewrite-target: /$1
          nginx.ingress.kubernetes.io/enable-cors: "true"
      spec:  
        rules:
        - host: 10.11.143.48.nip.io
          http:
            paths:
            - path: /nginx/?(.*)
              backend:
                serviceName: nginx-svc
                servicePort: 80
            - path: /?(.*)
              backend:
                serviceName: ratingsweb-service
                servicePort: 80
            - path: /bkend/?(.*)
              backend:
                serviceName: ratingsapi-service
                servicePort: 80
      ```

    - **Deploy** Ingress object

      ```bash
      kubectl apply -f <ingress_file_name>.yaml
      ```

    - This is used in the workshop. Users can bring in their own Ingress object as per the requirements

      

22. **Deploy** MicroServices

    - This can be done in multiple ways. This workshop deploys some ready-made micro-services using ACR build option. The applications deployed are as examples only!

    - Following steps deploys various components and services

      - **Namespaces**

        ```bash
        kubectl create ns ash-workshop-dev
        ```

      - **MongoDB**

        ```bash
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm search repo bitnami
        helm install ratingsdb bitnami/mongodb --namespace db --set auth.username=ratings-user,auth.password=ratings-pwd,auth.database=ratingsdb --set nodeSelector.agentpool=ashsyspool,defaultBackend.nodeSelector.agentpool=ashsyspool
        ```

      - **Secrets**

        ```bash
        kubectl create secret generic ash-mongo-secret --namespace ash-workshop-dev --from-literal=MONGOCONNECTION="mongodb://ratings-user:ratings-pwd@ratingsdb-mongodb.db:27017/ratingsdb"
        
        kubectl create secret docker-registry ash-acr-secret -n ash-workshop-dev --docker-server=<acr_server_name> --docker-username=<acr_user_name> --docker-password=<acr_user_password>
        ```

      - **Build and Push Images to ACR**

        ```bash
        # Build RatingsAPI Image
        az acr build -r <acr_name> https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api -t azcashacr.azurecr.io/ratings-api:v1.0.0
        
        # Build RatingsWeb Image
        az acr build -r <acr_name> https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web -t azcashacr.azurecr.io/ratings-web:v1.0.0
        ```

      - **Deploy** APIs

        - **Nginx** - ***APIs/YAMLs/DEV/Nginx***

          ```bash
          kubectl apply -f <nginx_folder_path>
          ```

        - **RatingsWeb** - ***APIs/YAMLs/DEV/RatingsWeb***

          ```bash
          kubectl apply -f <rtingsweb_folder_path>
          ```

        - **RatingsWeb** - ***APIs/YAMLs/DEV/RatingsAPI***

          ```bash
          kubectl apply -f <rtingsapi_folder_path>
          ```

23. **Remove** K8s Cluster from Stack Hub

    - Since this is an unmanaged K8s cluster, lifecycle of each component & resources created are to be maintained by the user(s)

    - Deletion of each resource is painful through a script; can anyway be done manually by pick-n-choose method!

    - Alternate option is to remove the entire resource group on Azure Stack Hub which contains all the resources - K8s as well as ancillary services

    - The following script would actually remove the rescue group

    - Run ***Deployments/Azure-CLI/Setup/ash-cluster-remove.ps1***

      - ***Example***

        ```bash
        ./ash-cluster-remove.ps1 --resourceGroup = "ash-workshop-rg"
        --bastionResourceGroup "<bastion_Resource_Group>" --ashVNetName "ash-workshop-vnet"
        --bastionVNetName "master-hub-vnet" --subscriptionId "<subscription_Id>"
        ```

      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following 2 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

          - **bastionResourceGroup** - The resource group name of the Jump Server machine

        - This scripts does following resources on *Azure Stack Cloud*

          - Delete the peering between Jump Server Subnet (i.e. *master-hub-vnet*) and the K8s Cluster Subnet (i.e. *ash-workshop-vnet*)

          - Delete the resource group on Stack Hub containing all the resources (i.e. *ash-workshop-rg*)

            

### References

