# Deployment Guide

This guide provides step-by-step instructions for deploying the retail store infrastructure to Azure.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Pre-Deployment Setup](#pre-deployment-setup)
- [Deployment Methods](#deployment-methods)
  - [Method 1: Manual Deployment (Local)](#method-1-manual-deployment-local)
  - [Method 2: GitHub Actions](#method-2-github-actions)
  - [Method 3: Azure Pipelines](#method-3-azure-pipelines)
- [Post-Deployment Configuration](#post-deployment-configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## Prerequisites

### Required Tools

Install the following tools on your local machine:

1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   # Install on Windows (using winget)
   winget install Microsoft.AzureCLI

   # Install on macOS (using Homebrew)
   brew install azure-cli

   # Install on Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Verify installation
   az --version
   ```

2. **Bicep CLI** (comes with Azure CLI)
   ```bash
   # Verify Bicep installation
   az bicep version

   # Upgrade Bicep to latest version
   az bicep upgrade
   ```

3. **kubectl** (Kubernetes command-line tool)
   ```bash
   # Install via Azure CLI
   az aks install-cli

   # Or install manually
   # macOS
   brew install kubectl

   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/

   # Verify installation
   kubectl version --client
   ```

4. **Helm** (Kubernetes package manager)
   ```bash
   # Install on macOS
   brew install helm

   # Install on Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

   # Install on Windows
   winget install Helm.Helm

   # Verify installation
   helm version
   ```

5. **Git**
   ```bash
   # Install on macOS
   brew install git

   # Install on Linux
   sudo apt-get install git

   # Install on Windows
   winget install Git.Git

   # Verify installation
   git --version
   ```

### Azure Requirements

- **Azure Subscription**: Active subscription with at least $100/month available
- **Permissions**: Contributor role on the subscription or resource group
- **Resource Quota**: Ensure sufficient quota for:
  - Virtual networks
  - Public IPs
  - Standard Load Balancers
  - VMs (for AKS nodes)

## Pre-Deployment Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Demo-aks
```

### 2. Login to Azure

```bash
# Interactive login
az login

# List available subscriptions
az account list --output table

# Set the active subscription
az account set --subscription "<subscription-id-or-name>"

# Verify current subscription
az account show --output table
```

### 3. Register Required Resource Providers

```bash
# Register required providers (if not already registered)
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.Sql
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights

# Check registration status
az provider show --namespace Microsoft.ContainerService --query "registrationState"
```

### 4. Configure Parameters

Edit the parameter file for your environment:

```bash
# Open the dev parameters file
code infra/bicep/parameters/dev.bicepparam
# or
nano infra/bicep/parameters/dev.bicepparam
```

**Update these values**:

```bicep
// Change the SQL admin username and password
param sqlAdminUsername = 'youradminuser'
param sqlAdminPassword = 'YourSecureP@ssw0rd123!'  // 🔐 Use strong password!

// Optional: Update project name and tags
param projectName = 'retail'  // Keep it short (3-10 chars)
param tags = {
  Environment: 'Development'
  Project: 'Retail Store'
  Owner: 'YourName'
  // Add more tags as needed
}
```

**⚠️ Security Warning**: Never commit passwords to source control! Consider using:
- Azure Key Vault references
- Environment variables
- CI/CD pipeline secrets

### 5. Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="rg-retail-dev"
LOCATION="southcentralus"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags Environment=Development Project=RetailStore

# Verify creation
az group show --name $RESOURCE_GROUP --output table
```

## Deployment Methods

### Method 1: Manual Deployment (Local)

This method deploys directly from your local machine.

#### Step 1: Validate Bicep Template

```bash
# Navigate to Bicep directory
cd infra/bicep

# Build Bicep file to validate syntax
az bicep build --file main.bicep

# Preview changes with What-If
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters parameters/dev.bicepparam
```

#### Step 2: Deploy Infrastructure

```bash
# Deploy the infrastructure
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters parameters/dev.bicepparam \
  --name "retail-infrastructure-$(date +%Y%m%d-%H%M%S)"

# This will take approximately 10-15 minutes
```

#### Step 3: Save Deployment Outputs

```bash
# Get deployment outputs
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name <deployment-name> \
  --query properties.outputs

# Save to file for reference
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name <deployment-name> \
  --query properties.outputs > deployment-outputs.json
```

### Method 2: GitHub Actions

This method uses GitHub Actions for automated deployment.

#### Step 1: Create Azure Service Principal

```bash
# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-retail-sp" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth

# Save the JSON output - you'll need it for GitHub secrets
```

#### Step 2: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

   | Secret Name | Value |
   |-------------|-------|
   | `AZURE_CREDENTIALS` | JSON output from service principal creation |
   | `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |
   | `SQL_ADMIN_PASSWORD` | Your SQL admin password |

#### Step 3: Update Workflow File

Edit `.github/workflows/deploy-infrastructure.yml`:

```yaml
env:
  AZURE_RESOURCE_GROUP: 'rg-retail-dev'  # Update if different
  AZURE_LOCATION: 'southcentralus'       # Update if different
```

#### Step 4: Run Workflow

1. Go to **Actions** tab in your GitHub repository
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Select environment (dev/staging/prod)
5. Click **Run workflow** button

Monitor the workflow execution in the Actions tab.

### Method 3: Azure Pipelines

This method uses Azure DevOps Pipelines.

#### Step 1: Create Azure DevOps Project

1. Navigate to https://dev.azure.com
2. Create new project: "Retail-Store"
3. Initialize Git repository (or import from GitHub)

#### Step 2: Create Service Connection

1. Go to **Project Settings** → **Service connections**
2. Click **New service connection**
3. Select **Azure Resource Manager**
4. Choose **Service principal (automatic)**
5. Configure:
   - **Scope**: Resource Group
   - **Resource Group**: rg-retail-dev
   - **Service connection name**: azure-retail-dev
6. Save the connection

#### Step 3: Create Variable Group

1. Go to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name: `retail-dev-vars`
4. Add variable:
   - Name: `SQL_ADMIN_PASSWORD`
   - Value: Your SQL password
   - 🔒 Click the lock icon to make it secret
5. Save

#### Step 4: Update Pipeline File

Edit `infra/pipelines/azure-pipelines.yml`:

```yaml
variables:
  azureSubscription: 'azure-retail-dev'  # Match your service connection name
  resourceGroupName: 'rg-retail-dev'
  location: 'southcentralus'
```

#### Step 5: Create and Run Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Select `/infra/pipelines/azure-pipelines.yml`
6. Click **Run**

Monitor the pipeline execution.

## Post-Deployment Configuration

### 1. Connect to AKS Cluster

```bash
# Get AKS cluster name from deployment outputs
AKS_CLUSTER_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name <deployment-name> \
  --query 'properties.outputs.aksClusterName.value' \
  --output tsv)

# Get AKS credentials
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --overwrite-existing

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2. Install Application Gateway for Containers (ALB) Controller

```bash
# Install ALB Controller via Helm
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
  --version 1.0.0 \
  --set albController.namespace=azure-alb-system \
  --namespace azure-alb-system \
  --create-namespace

# Wait for ALB controller to be ready
kubectl wait --namespace azure-alb-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=alb-controller \
  --timeout=120s

# Verify installation
kubectl get pods -n azure-alb-system
kubectl get gatewayclass

# Note: The Application Gateway for Containers infrastructure
# was already deployed via Bicep. This step installs the controller
# that manages the ingress resources within Kubernetes.
```

### 3. Create Kubernetes Secrets for SQL Connection

```bash
# Get SQL Server FQDN
SQL_SERVER_FQDN=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name <deployment-name> \
  --query 'properties.outputs.sqlServerFqdn.value' \
  --output tsv)

SQL_DATABASE_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name <deployment-name> \
  --query 'properties.outputs.sqlDatabaseName.value' \
  --output tsv)

# Create connection string secret
kubectl create secret generic sql-connection-string \
  --from-literal=connection-string="Server=tcp:${SQL_SERVER_FQDN},1433;Initial Catalog=${SQL_DATABASE_NAME};Persist Security Info=False;User ID=<sql-admin-username>;Password=<sql-admin-password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Verify secret creation
kubectl get secret sql-connection-string
```

### 4. Configure ACR Access

```bash
# Get ACR name
ACR_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name <deployment-name> \
  --query 'properties.outputs.acrName.value' \
  --output tsv)

# Login to ACR (for pushing images)
az acr login --name $ACR_NAME

# Verify AKS can pull from ACR (should already be configured via managed identity)
kubectl create deployment test-acr --image=${ACR_NAME}.azurecr.io/test:latest --dry-run=client -o yaml
```

### 5. Build and Push Container Images

#### Frontend (React)

```bash
cd src/frontend

# Build Docker image
docker build -t ${ACR_NAME}.azurecr.io/frontend:latest .

# Push to ACR
docker push ${ACR_NAME}.azurecr.io/frontend:latest

# Verify image in ACR
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository frontend --output table
```

#### Backend (.NET)

```bash
cd src/backend

# Build Docker image
docker build -t ${ACR_NAME}.azurecr.io/backend:latest .

# Push to ACR
docker push ${ACR_NAME}.azurecr.io/backend:latest

# Verify image in ACR
az acr repository show-tags --name $ACR_NAME --repository backend --output table
```

### 6. Deploy Applications to AKS

Create Kubernetes manifests for your applications (examples provided in `src/` directories).

```bash
# Deploy backend
kubectl apply -f src/backend/k8s/

# Deploy frontend
kubectl apply -f src/frontend/k8s/

# Verify deployments
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress
```

## Verification

### 1. Verify Infrastructure Resources

```bash
# List all resources in resource group
az resource list \
  --resource-group $RESOURCE_GROUP \
  --output table

# Check AKS cluster status
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --query "provisioningState"

# Check SQL Database status
az sql db show \
  --resource-group $RESOURCE_GROUP \
  --server <sql-server-name> \
  --name <database-name> \
  --query "status"
```

### 2. Verify AKS Cluster Health

```bash
# Check nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check for any issues
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### 3. Verify Private Endpoints

```bash
# Check ACR private endpoint
az network private-endpoint show \
  --resource-group $RESOURCE_GROUP \
  --name <acr-name>-pe

# Check SQL private endpoint
az network private-endpoint show \
  --resource-group $RESOURCE_GROUP \
  --name <sql-server-name>-pe
```

### 4. Test Connectivity

```bash
# Test pod can reach SQL Database
kubectl run -it --rm test-sql --image=mcr.microsoft.com/mssql-tools --restart=Never -- /bin/bash
# Inside the pod:
# sqlcmd -S <sql-server-fqdn> -U <username> -P <password> -Q "SELECT @@VERSION"

# Test pod can pull from ACR
kubectl run test-acr --image=${ACR_NAME}.azurecr.io/frontend:latest
kubectl get pods test-acr
```

## Troubleshooting

### Common Issues

#### Issue 1: Deployment Fails with "Quota Exceeded"

**Solution**:
```bash
# Check current quota
az vm list-usage --location $LOCATION --output table

# Request quota increase via Azure Portal:
# Portal → Subscriptions → Usage + quotas → Request increase
```

#### Issue 2: Cannot Connect to Private AKS Cluster

**Solution**:
```bash
# You need to be in the same VNet or use VPN/ExpressRoute
# For testing, enable public network access temporarily:
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --enable-public-fqdn

# Re-run get-credentials
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --overwrite-existing
```

#### Issue 3: Pods Cannot Pull Images from ACR

**Solution**:
```bash
# Check AKS managed identity has AcrPull role
az role assignment list \
  --scope $(az acr show --name $ACR_NAME --query id --output tsv) \
  --output table

# If missing, add role assignment
AKS_KUBELET_IDENTITY=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --query identityProfile.kubeletidentity.objectId \
  --output tsv)

az role assignment create \
  --assignee $AKS_KUBELET_IDENTITY \
  --role AcrPull \
  --scope $(az acr show --name $ACR_NAME --query id --output tsv)
```

#### Issue 4: SQL Connection Fails

**Solution**:
```bash
# Verify private endpoint is working
nslookup <sql-server-name>.database.windows.net

# Should resolve to private IP (10.0.3.x)

# Check firewall rules
az sql server firewall-rule list \
  --resource-group $RESOURCE_GROUP \
  --server <sql-server-name>

# Verify connection string in secret
kubectl get secret sql-connection-string -o jsonpath='{.data.connection-string}' | base64 --decode
```

#### Issue 5: High Costs

**Solution**:
```bash
# Check current spending
az consumption usage list \
  --start-date $(date -d '30 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table

# Scale down AKS nodes manually
az aks nodepool scale \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $AKS_CLUSTER_NAME \
  --name systempool \
  --node-count 1

# Stop AKS cluster when not in use (dev only!)
az aks stop \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME
```

### Getting Help

- **Azure Documentation**: https://docs.microsoft.com/azure
- **AKS Troubleshooting**: https://docs.microsoft.com/azure/aks/troubleshooting
- **Bicep Documentation**: https://docs.microsoft.com/azure/azure-resource-manager/bicep/
- **GitHub Issues**: Create an issue in this repository

## Cleanup

### Delete Individual Resources

```bash
# Stop AKS cluster (preserves cluster)
az aks stop \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME
```

### Delete Entire Resource Group

⚠️ **Warning**: This will delete ALL resources in the resource group!

```bash
# Delete resource group and all resources
az group delete \
  --name $RESOURCE_GROUP \
  --yes \
  --no-wait

# Check deletion status
az group show --name $RESOURCE_GROUP
```

### Cost Estimation Before Deletion

```bash
# Review resources before deletion
az resource list \
  --resource-group $RESOURCE_GROUP \
  --output table

# Get cost breakdown
az consumption usage list \
  --start-date $(date -d '30 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table
```

---

**Document Version**: 1.0
**Last Updated**: 2025
**Maintained By**: Infrastructure Team
