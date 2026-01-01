# Retail Store - Azure Kubernetes Service Infrastructure

A cost-optimized, production-ready infrastructure for a three-tier retail store application deployed on Azure Kubernetes Service (AKS) using Bicep as Infrastructure as Code.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Cost Estimation](#cost-estimation)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Deployment](#deployment)
- [Post-Deployment](#post-deployment)
- [Documentation](#documentation)
- [Technology Stack](#technology-stack)

## 🎯 Overview

This project provides a complete infrastructure setup for a three-tier retail store application:

- **Presentation Tier**: React frontend (containerized, running in AKS)
- **Application Tier**: .NET backend API (containerized, running in AKS)
- **Data Tier**: Azure SQL Database (separate managed service with private endpoint)

### Key Features

✅ **Private & Secure**: Private AKS cluster with private endpoints for ACR and SQL Database
✅ **Cost-Optimized**: Designed to stay within $100/month budget using Basic/Standard SKUs
✅ **Auto-Scaling**: AKS node pool scales from 1-3 nodes based on demand
✅ **Production-Ready**: Infrastructure monitoring with Log Analytics and Container Insights
✅ **Fully Automated**: Complete CI/CD pipelines for infrastructure deployment
✅ **Well-Documented**: Comprehensive documentation and inline code comments

## 🏗️ Architecture

The infrastructure consists of the following Azure resources:

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Subscription                      │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Resource Group: rg-retail-dev             │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │           Virtual Network (10.0.0.0/16)          │ │  │
│  │  │                                                  │ │  │
│  │  │  ┌─────────────────────────────────────────┐    │ │  │
│  │  │  │    AKS Subnet (10.0.1.0/24)            │    │ │  │
│  │  │  │                                         │    │ │  │
│  │  │  │  ┌────────────────────────────────┐    │    │ │  │
│  │  │  │  │  AKS Private Cluster           │    │    │ │  │
│  │  │  │  │  - System Node Pool (1-3 nodes)│    │    │ │  │
│  │  │  │  │  - Auto-scaling enabled        │    │    │ │  │
│  │  │  │  │  - NGINX Ingress Controller    │    │    │ │  │
│  │  │  │  │                                │    │    │ │  │
│  │  │  │  │  Pods:                         │    │    │ │  │
│  │  │  │  │  ├─ Frontend (React)           │    │    │ │  │
│  │  │  │  │  └─ Backend (.NET)             │    │    │ │  │
│  │  │  │  └────────────────────────────────┘    │    │ │  │
│  │  │  └─────────────────────────────────────────┘    │ │  │
│  │  │                                                  │ │  │
│  │  │  ┌─────────────────────────────────────────┐    │ │  │
│  │  │  │  Private Endpoints Subnet (10.0.3.0/24) │    │ │  │
│  │  │  │                                         │    │ │  │
│  │  │  │  ├─ ACR Private Endpoint              │    │ │  │
│  │  │  │  └─ SQL Private Endpoint              │    │ │  │
│  │  │  └─────────────────────────────────────────┘    │ │  │
│  │  │                                                  │ │  │
│  │  │  ┌─────────────────────────────────────────┐    │ │  │
│  │  │  │  App Gateway Subnet (10.0.2.0/24)      │    │ │  │
│  │  │  │  (Reserved for future use)             │    │ │  │
│  │  │  └─────────────────────────────────────────┘    │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │  Azure Container Registry (Private)              │ │  │
│  │  │  - Stores frontend and backend images            │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │  Azure SQL Database (Private)                    │ │  │
│  │  │  - Basic Tier (2 GB)                             │ │  │
│  │  │  - Retail store data                             │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │  Log Analytics Workspace                         │ │  │
│  │  │  - AKS monitoring                                │ │  │
│  │  │  - Container logs                                │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

See [docs/architecture.md](docs/architecture.md) for detailed architecture documentation.

## 💰 Cost Estimation

**Target Budget**: $100/month (out of $150 Azure credits)

| Resource | SKU/Size | Estimated Monthly Cost |
|----------|----------|------------------------|
| AKS Control Plane | Free Tier | $0 |
| AKS Node Pool | 1-3x Standard_B2s | $30-90 |
| Azure SQL Database | Basic (2 GB) | ~$5 |
| Azure Container Registry | Basic | ~$5 |
| Virtual Network | Standard | $0 (basic usage) |
| Private Endpoints | 2x endpoints | ~$14 |
| Log Analytics | Pay-as-you-go | ~$5-10 |
| **Total** | | **$59-124/month** ✅ |

### Cost Optimization Tips

- Auto-scaling keeps nodes at minimum (1) during low usage
- Using Basic/Standard SKUs instead of Premium
- No Application Gateway for Containers (saves ~$70-100/month)
- Using NGINX Ingress Controller (free) instead

## 📦 Prerequisites

### Local Development

- Azure CLI (`az`) version 2.50.0 or later
- Bicep CLI (comes with Azure CLI)
- kubectl (for AKS management)
- Helm 3.x (for installing charts)
- Git
- An Azure subscription with at least $100/month available

### For CI/CD

- GitHub Account (for GitHub Actions) OR Azure DevOps (for Azure Pipelines)
- Azure Service Principal or Managed Identity for deployments

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Demo-aks
```

### 2. Update Parameters

Edit `infra/bicep/parameters/dev.bicepparam`:

```bicep
param sqlAdminUsername = 'youradminuser'
param sqlAdminPassword = 'YourSecurePassword123!'  // Use Key Vault in production!
```

### 3. Login to Azure

```bash
az login
az account set --subscription <your-subscription-id>
```

### 4. Create Resource Group

```bash
az group create \
  --name rg-retail-dev \
  --location southcentralus
```

### 5. Deploy Infrastructure

```bash
az deployment group create \
  --resource-group rg-retail-dev \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/dev.bicepparam
```

Deployment takes approximately 10-15 minutes.

### 6. Verify Deployment

```bash
# Get AKS credentials
az aks get-credentials --name <aks-cluster-name> --resource-group rg-retail-dev

# Check nodes
kubectl get nodes

# Login to ACR
az acr login --name <acr-name>
```

## 📁 Project Structure

```
Demo-aks/
├── .github/
│   └── workflows/
│       └── deploy-infrastructure.yml    # GitHub Actions workflow
├── docs/
│   ├── architecture.md                  # Detailed architecture documentation
│   └── deployment-guide.md              # Step-by-step deployment guide
├── infra/
│   ├── bicep/
│   │   ├── main.bicep                   # Main orchestration template
│   │   ├── modules/
│   │   │   ├── network.bicep            # Virtual network and subnets
│   │   │   ├── aks.bicep                # AKS cluster
│   │   │   ├── acr.bicep                # Container registry
│   │   │   ├── sql.bicep                # SQL Database
│   │   │   ├── monitoring.bicep         # Log Analytics
│   │   │   └── appgw-containers.bicep   # App Gateway (future use)
│   │   └── parameters/
│   │       └── dev.bicepparam           # Development parameters
│   └── pipelines/
│       └── azure-pipelines.yml          # Azure Pipelines workflow
├── src/
│   ├── frontend/                        # React frontend (placeholder)
│   └── backend/                         # .NET backend (placeholder)
├── .gitignore
└── README.md
```

## 🔧 Deployment

### Option 1: Manual Deployment (Local)

See [Quick Start](#quick-start) above.

### Option 2: GitHub Actions

1. Configure GitHub secrets:
   - `AZURE_CREDENTIALS`
   - `AZURE_SUBSCRIPTION_ID`
   - `SQL_ADMIN_PASSWORD`

2. Trigger workflow manually or push to main branch

3. Monitor workflow in GitHub Actions tab

### Option 3: Azure Pipelines

1. Create Azure DevOps service connection
2. Create variable group with `SQL_ADMIN_PASSWORD`
3. Update `infra/pipelines/azure-pipelines.yml` with your service connection name
4. Run pipeline

See [docs/deployment-guide.md](docs/deployment-guide.md) for detailed instructions.

## 🎯 Post-Deployment

### Install NGINX Ingress Controller

```bash
# Add Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### Create SQL Connection Secret

```bash
kubectl create secret generic sql-connection-string \
  --from-literal=connection-string="Server=<sql-server-fqdn>;Database=retailDB;User Id=<username>;Password=<password>"
```

### Build and Push Container Images

```bash
# Login to ACR
az acr login --name <acr-name>

# Build and push frontend
docker build -t <acr-name>.azurecr.io/frontend:latest ./src/frontend
docker push <acr-name>.azurecr.io/frontend:latest

# Build and push backend
docker build -t <acr-name>.azurecr.io/backend:latest ./src/backend
docker push <acr-name>.azurecr.io/backend:latest
```

## 📚 Documentation

- [Architecture Documentation](docs/architecture.md) - Detailed architecture and design decisions
- [Deployment Guide](docs/deployment-guide.md) - Step-by-step deployment instructions
- [Application Gateway for Containers](infra/bicep/modules/appgw-containers.bicep) - Future upgrade path

## 🛠️ Technology Stack

### Infrastructure

- **IaC**: Bicep
- **Container Orchestration**: Azure Kubernetes Service (AKS)
- **Container Registry**: Azure Container Registry (ACR)
- **Database**: Azure SQL Database
- **Networking**: Azure Virtual Network with private endpoints
- **Monitoring**: Azure Monitor, Log Analytics, Container Insights
- **Ingress**: NGINX Ingress Controller

### Application (Planned)

- **Frontend**: React
- **Backend**: .NET (ASP.NET Core)
- **Database**: SQL Server

### CI/CD

- GitHub Actions
- Azure Pipelines (alternative)

## 🔐 Security Features

- ✅ Private AKS cluster (no public API endpoint)
- ✅ Private endpoints for ACR and SQL Database
- ✅ Network policies with Azure CNI
- ✅ Managed identities for service authentication
- ✅ TLS 1.2 minimum for SQL connections
- ✅ No admin user for ACR (using managed identity)

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test deployments
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Review the [deployment guide](docs/deployment-guide.md)
- Check Azure documentation

---

**Built with ❤️ for learning and development**
