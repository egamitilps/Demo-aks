# Architecture Documentation

## Overview

This document provides a comprehensive overview of the retail store application infrastructure deployed on Azure Kubernetes Service (AKS). The architecture follows a three-tier pattern with emphasis on security, cost optimization, and scalability.

## Table of Contents

- [Architecture Diagram](#architecture-diagram)
- [Three-Tier Application Design](#three-tier-application-design)
- [Infrastructure Components](#infrastructure-components)
- [Network Architecture](#network-architecture)
- [Security Architecture](#security-architecture)
- [Scalability and Performance](#scalability-and-performance)
- [Monitoring and Observability](#monitoring-and-observability)
- [Cost Optimization Strategy](#cost-optimization-strategy)
- [Design Decisions](#design-decisions)
- [Future Enhancements](#future-enhancements)

## Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                           Azure Cloud Environment                              │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                     Resource Group: rg-retail-dev                         │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                  Virtual Network (10.0.0.0/16)                      │ │ │
│  │  │                                                                     │ │ │
│  │  │   ┌──────────────────────────────────────────────────────────────┐ │ │ │
│  │  │   │             AKS Subnet (10.0.1.0/24)                         │ │ │ │
│  │  │   │                                                              │ │ │ │
│  │  │   │   ┌────────────────────────────────────────────────────┐     │ │ │ │
│  │  │   │   │   Azure Kubernetes Service (Private Cluster)       │     │ │ │ │
│  │  │   │   │                                                    │     │ │ │ │
│  │  │   │   │   Control Plane (Private API Server)              │     │ │ │ │
│  │  │   │   │   ├─ Private FQDN                                 │     │ │ │ │
│  │  │   │   │   └─ No public endpoint                           │     │ │ │ │
│  │  │   │   │                                                    │     │ │ │ │
│  │  │   │   │   System Node Pool (VMs: Standard_B2s)            │     │ │ │ │
│  │  │   │   │   ├─ Auto-scaling: 1-3 nodes                      │     │ │ │ │
│  │  │   │   │   ├─ Max 30 pods per node                         │     │ │ │ │
│  │  │   │   │   └─ Managed identity for ACR access              │     │ │ │ │
│  │  │   │   │                                                    │     │ │ │ │
│  │  │   │   │   Workloads:                                      │     │ │ │ │
│  │  │   │   │   ┌──────────────────────────────────────┐        │     │ │ │ │
│  │  │   │   │   │  Presentation Tier                   │        │     │ │ │ │
│  │  │   │   │   │  ┌────────────────────────────────┐  │        │     │ │ │ │
│  │  │   │   │   │  │  Frontend Pod (React)          │  │        │     │ │ │ │
│  │  │   │   │   │  │  - Nginx web server            │  │        │     │ │ │ │
│  │  │   │   │   │  │  - Static assets               │  │        │     │ │ │ │
│  │  │   │   │   │  │  - Service: ClusterIP          │  │        │     │ │ │ │
│  │  │   │   │   │  └────────────────────────────────┘  │        │     │ │ │ │
│  │  │   │   │   └──────────────────────────────────────┘        │     │ │ │ │
│  │  │   │   │                      ▲                            │     │ │ │ │
│  │  │   │   │                      │                            │     │ │ │ │
│  │  │   │   │   ┌──────────────────┴───────────────────┐        │     │ │ │ │
│  │  │   │   │   │  App Gateway for Containers          │        │     │ │ │ │
│  │  │   │   │   │  - Internal Load Balancer            │        │     │ │ │ │
│  │  │   │   │   │  - TLS termination                   │        │     │ │ │ │
│  │  │   │   │   │  - Routing rules                     │        │     │ │ │ │
│  │  │   │   │   └──────────────────────────────────────┘        │     │ │ │ │
│  │  │   │   │                                                    │     │ │ │ │
│  │  │   │   │   ┌──────────────────────────────────────┐        │     │ │ │ │
│  │  │   │   │   │  Application Tier                    │        │     │ │ │ │
│  │  │   │   │   │  ┌────────────────────────────────┐  │        │     │ │ │ │
│  │  │   │   │   │  │  Backend Pod (.NET Core)       │  │        │     │ │ │ │
│  │  │   │   │   │  │  - REST API                    │  │        │     │ │ │ │
│  │  │   │   │   │  │  - Business logic              │  │        │     │ │ │ │
│  │  │   │   │   │  │  - Service: ClusterIP          │  │        │     │ │ │ │
│  │  │   │   │   │  │  - SQL connection via PE       │◄─┼────────┼─┐   │ │ │ │
│  │  │   │   │   │  └────────────────────────────────┘  │        │ │   │ │ │ │
│  │  │   │   │   └──────────────────────────────────────┘        │ │   │ │ │ │
│  │  │   │   └────────────────────────────────────────────────────┘ │   │ │ │ │
│  │  │   └──────────────────────────────────────────────────────────┘   │ │ │ │
│  │  │                                                                   │ │ │ │
│  │  │   ┌──────────────────────────────────────────────────────────┐   │ │ │ │
│  │  │   │      Private Endpoints Subnet (10.0.3.0/24)              │   │ │ │ │
│  │  │   │                                                          │   │ │ │ │
│  │  │   │   ┌────────────────────────────────────────┐             │   │ │ │ │
│  │  │   │   │  ACR Private Endpoint                  │             │   │ │ │ │
│  │  │   │   │  - Private IP: 10.0.3.4                │             │   │ │ │ │
│  │  │   │   │  - DNS: privatelink.azurecr.io         │◄────────────┼───┼─┤ │ │
│  │  │   │   └────────────────────────────────────────┘             │   │ │ │ │
│  │  │   │                                                          │   │ │ │ │
│  │  │   │   ┌────────────────────────────────────────┐             │   │ │ │ │
│  │  │   │   │  SQL Private Endpoint                  │             │   │ │ │ │
│  │  │   │   │  - Private IP: 10.0.3.5                │◄────────────┼───┘ │ │ │
│  │  │   │   │  - DNS: privatelink.database.windows...│             │     │ │ │
│  │  │   │   └────────────────────────────────────────┘             │     │ │ │
│  │  │   └──────────────────────────────────────────────────────────┘     │ │ │
│  │  │                                                                     │ │ │
│  │  │   ┌──────────────────────────────────────────────────────────┐     │ │ │
│  │  │   │   App Gateway Subnet (10.0.2.0/24) - Reserved           │     │ │ │
│  │  │   │   (For future Application Gateway for Containers)        │     │ │ │
│  │  │   └──────────────────────────────────────────────────────────┘     │ │ │
│  │  │                                                                     │ │ │
│  │  │   ┌──────────────────────────────────────────────────────────┐     │ │ │
│  │  │   │  Private DNS Zones                                       │     │ │ │
│  │  │   │  - privatelink.azurecr.io                                │     │ │ │
│  │  │   │  - privatelink.database.windows.net                      │     │ │ │
│  │  │   └──────────────────────────────────────────────────────────┘     │ │ │
│  │  └─────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  Azure Container Registry (ACR)                                     │ │ │
│  │  │  ┌───────────────────────────────────────────────────────────────┐  │ │ │
│  │  │  │  Registry: retaildevacr<unique>                              │  │ │ │
│  │  │  │  - SKU: Basic                                                │  │ │ │
│  │  │  │  - Public access: Disabled                                   │  │ │ │
│  │  │  │  - Private endpoint enabled                                  │  │ │ │
│  │  │  │                                                              │  │ │ │
│  │  │  │  Repositories:                                               │  │ │ │
│  │  │  │  ├─ frontend:latest (React application)                     │  │ │ │
│  │  │  │  └─ backend:latest (.NET API)                               │  │ │ │
│  │  │  └───────────────────────────────────────────────────────────────┘  │ │ │
│  │  └─────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  Azure SQL Database                                                 │ │ │
│  │  │  ┌───────────────────────────────────────────────────────────────┐  │ │ │
│  │  │  │  Server: retail-dev-sql-<unique>                             │  │ │ │
│  │  │  │  Database: retailDB                                          │  │ │ │
│  │  │  │  - SKU: Basic (2 GB)                                         │  │ │ │
│  │  │  │  - Public access: Disabled                                   │  │ │ │
│  │  │  │  - Private endpoint enabled                                  │  │ │ │
│  │  │  │  - TLS 1.2 minimum                                           │  │ │ │
│  │  │  │                                                              │  │ │ │
│  │  │  │  Data Tier:                                                  │  │ │ │
│  │  │  │  ├─ Products table                                          │  │ │ │
│  │  │  │  ├─ Orders table                                            │  │ │ │
│  │  │  │  ├─ Customers table                                         │  │ │ │
│  │  │  │  └─ Inventory table                                         │  │ │ │
│  │  │  └───────────────────────────────────────────────────────────────┘  │ │ │
│  │  └─────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  Log Analytics Workspace                                            │ │ │
│  │  │  - Container Insights                                               │ │ │
│  │  │  - AKS metrics and logs                                             │ │ │
│  │  │  - Application logs                                                 │ │ │
│  │  │  - 30-day retention                                                 │ │ │
│  │  └─────────────────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────────┘
```

## Three-Tier Application Design

### Tier 1: Presentation Layer (Frontend)

**Technology**: React Single Page Application

**Hosting**: Containerized in AKS
- Nginx web server serving static files
- Deployed as Kubernetes Deployment with multiple replicas
- Exposed via Kubernetes ClusterIP Service
- Accessed through Application Gateway for Containers

**Responsibilities**:
- User interface rendering
- Client-side routing
- API calls to backend
- Session management
- Form validation

### Tier 2: Application Layer (Backend)

**Technology**: .NET Core Web API

**Hosting**: Containerized in AKS
- RESTful API endpoints
- Deployed as Kubernetes Deployment with multiple replicas
- Exposed via Kubernetes ClusterIP Service
- Internal communication only (no direct internet access)

**Responsibilities**:
- Business logic execution
- Data validation
- Authentication and authorization
- Database connectivity (via private endpoint)
- API endpoints for CRUD operations

### Tier 3: Data Layer

**Technology**: Azure SQL Database (Basic tier)

**Hosting**: Azure PaaS (managed service)
- Separate from AKS cluster
- Accessed via private endpoint only
- No public internet access

**Responsibilities**:
- Data persistence
- Transaction management
- Data integrity enforcement
- Backup and recovery

## Infrastructure Components

### 1. Azure Kubernetes Service (AKS)

**Configuration**:
- **Cluster Type**: Private cluster
- **Kubernetes Version**: 1.28.9
- **Network Plugin**: Azure CNI
- **Network Policy**: Azure Network Policy
- **Node Pool**:
  - Name: systempool
  - VM Size: Standard_B2s (2 vCPU, 4 GB RAM)
  - OS Disk: 30 GB SSD
  - Auto-scaling: Enabled (1-3 nodes)
  - Max pods per node: 30

**Features**:
- System-assigned managed identity
- Container Insights enabled
- Auto-upgrade channel: stable
- Private API server endpoint
- Integration with ACR via managed identity

### 2. Azure Container Registry (ACR)

**Configuration**:
- **SKU**: Basic
- **Public Access**: Disabled
- **Admin User**: Disabled
- **Private Endpoint**: Enabled
- **Network**: Connected to private endpoints subnet

**Features**:
- Stores Docker images for frontend and backend
- Accessed by AKS via managed identity (AcrPull role)
- Private DNS zone integration

### 3. Azure SQL Database

**Configuration**:
- **Server**: SQL Server 12.0
- **Database SKU**: Basic
- **Storage**: 2 GB
- **Public Access**: Disabled
- **TLS**: Minimum 1.2
- **Private Endpoint**: Enabled

**Features**:
- Firewall rule for Azure services
- Private DNS zone integration
- Automatic backups (7-day retention for Basic)
- Local backup redundancy

### 4. Virtual Network

**Configuration**:
- **Address Space**: 10.0.0.0/16
- **Subnets**:
  1. AKS Subnet: 10.0.1.0/24 (supports ~250 IPs)
  2. App Gateway Subnet: 10.0.2.0/24 (reserved for future)
  3. Private Endpoints Subnet: 10.0.3.0/24

**Features**:
- Subnet delegation for Application Gateway for Containers
- Private endpoint network policies disabled
- Integration with Azure CNI for AKS

### 5. Log Analytics Workspace

**Configuration**:
- **SKU**: PerGB2018 (pay-as-you-go)
- **Retention**: 30 days
- **Solutions**: Container Insights

**Features**:
- AKS cluster monitoring
- Container logs aggregation
- Performance metrics
- Query capabilities with KQL

## Network Architecture

### Network Flow

```
Internet
   │
   ▼
[Application Gateway for Containers - Azure-Native Ingress]
   │
   ├──► Frontend Service (ClusterIP)
   │       └──► Frontend Pods
   │
   └──► Backend Service (ClusterIP)
           └──► Backend Pods
                   │
                   ├──► ACR (via Private Endpoint 10.0.3.4)
                   │
                   └──► SQL Database (via Private Endpoint 10.0.3.5)
```

### Private Endpoints

**Purpose**: Secure private connectivity from VNet to PaaS services

**Configured For**:
1. Azure Container Registry
   - Private IP: 10.0.3.x
   - DNS Zone: privatelink.azurecr.io

2. Azure SQL Database
   - Private IP: 10.0.3.x
   - DNS Zone: privatelink.database.windows.net

**Benefits**:
- No data traverses public internet
- Reduced attack surface
- Compliance with security requirements

### DNS Configuration

**Private DNS Zones**:
- Created for ACR and SQL Database
- Linked to Virtual Network
- Automatic A record creation for private endpoints
- Resolves private endpoint names to private IPs within VNet

## Security Architecture

### Defense in Depth

**Layer 1: Network Security**
- Private AKS cluster (no public API endpoint)
- Network segmentation with subnets
- Private endpoints for all PaaS services
- Network policies in AKS

**Layer 2: Identity and Access**
- Managed identities (no credentials in code)
- RBAC for AKS
- Least privilege principle
- No ACR admin user

**Layer 3: Data Security**
- TLS 1.2 minimum for SQL
- Encryption at rest (default for all Azure services)
- Encryption in transit
- SQL connection strings in Kubernetes secrets

**Layer 4: Application Security**
- Container image scanning (recommended to add)
- Vulnerability management
- Regular updates via auto-upgrade

### Security Best Practices Implemented

✅ No public endpoints for AKS, ACR, or SQL
✅ Managed identities instead of service principals
✅ Private DNS zones for name resolution
✅ Network policies for pod-to-pod communication
✅ Secrets stored in Kubernetes secrets (recommend Azure Key Vault integration)
✅ RBAC enabled on AKS

## Scalability and Performance

### AKS Auto-Scaling

**Horizontal Pod Autoscaling (HPA)**:
- Recommended for both frontend and backend deployments
- Scale based on CPU/memory utilization
- Example: 2-10 replicas per deployment

**Cluster Autoscaling**:
- Node pool auto-scales from 1 to 3 nodes
- Triggers based on pod resource requests
- Scale-down delay: 10 minutes (default)

### Performance Optimization

**AKS**:
- Azure CNI for better network performance
- Standard Load Balancer SKU
- SSD-based OS disks
- Resource requests and limits for pods

**SQL Database**:
- Connection pooling in .NET backend
- Indexed tables for query performance
- Consider upgrading to Standard tier for production

**ACR**:
- Basic tier sufficient for dev/learning
- Consider upgrading to Standard/Premium for:
  - Geo-replication
  - Larger storage
  - Higher bandwidth

## Monitoring and Observability

### Container Insights

**Metrics Collected**:
- Node CPU and memory utilization
- Pod resource usage
- Container performance
- Cluster health

**Logs Collected**:
- Container logs (stdout/stderr)
- Kubernetes events
- AKS diagnostics

### Recommended Dashboards

1. **AKS Cluster Overview**
   - Node health
   - Pod status
   - Resource utilization

2. **Application Performance**
   - Request rates
   - Response times
   - Error rates

3. **Cost Analysis**
   - Node utilization
   - Wasted resources
   - Optimization opportunities

### Alerting Strategy

**Recommended Alerts**:
- Node CPU > 80% for 10 minutes
- Node memory > 80% for 10 minutes
- Pod restart count > 5 in 10 minutes
- Failed deployments
- AKS cluster health degraded

## Cost Optimization Strategy

### Current Optimizations

1. **Free AKS Control Plane**: Using free tier
2. **Basic SKUs**: ACR Basic, SQL Basic
3. **Auto-Scaling**: Nodes scale down to 1 during low usage
4. **B-series VMs**: Burstable VMs for variable workloads
5. **Application Gateway for Containers**: Azure-native managed ingress
6. **Minimal Retention**: 30-day log retention

### Cost Monitoring

**Tools**:
- Azure Cost Management
- Resource tags for cost allocation
- Budget alerts

**Recommendations**:
- Set budget alert at $80/month (80% of $100)
- Review cost weekly
- Delete unused resources promptly

## Design Decisions

### Why Private Cluster?

**Pros**:
- Enhanced security
- No public API endpoint exposure
- Better compliance posture

**Cons**:
- Requires jump box or VPN for kubectl access
- More complex CI/CD setup

**Decision**: Security takes priority for production-ready architecture

### Why Application Gateway for Containers?

**Benefits**:
- Fully managed Azure service (no self-managed pods)
- Native integration with Azure ecosystem
- Advanced routing and WAF capabilities
- Enterprise-grade security and compliance
- Auto-scaling and high availability

**Trade-offs**:
- Additional cost ($70-100/month)
- More complex initial setup than simple ingress controllers

**Decision**: Use Azure-native Application Gateway for Containers for production-ready, fully-managed infrastructure that aligns with Azure best practices

### Why Basic SQL Tier?

**Pros**:
- Lowest cost (~$5/month)
- Sufficient for dev/learning
- Includes automatic backups

**Cons**:
- Limited DTUs
- Lower performance
- 2 GB max size

**Decision**: Appropriate for learning environment, upgrade to Standard for production

### Why Azure CNI vs Kubenet?

**Azure CNI Pros**:
- Better network performance
- Direct pod IPs from VNet
- Easier private endpoint connectivity
- Better integration with Azure services

**Kubenet Cons**:
- NAT for pod traffic
- More complex networking

**Decision**: Azure CNI for better integration and performance

## Future Enhancements

### Recommended Upgrades

1. **Application Gateway for Containers** (when budget allows)
   - Advanced routing capabilities
   - Web Application Firewall (WAF)
   - Better Azure integration

2. **Azure Key Vault Integration**
   - Secrets stored outside Kubernetes
   - CSI driver for seamless access
   - Secret rotation

3. **Azure AD Pod Identity / Workload Identity**
   - Managed identities for pods
   - No secrets in pods

4. **Azure Policy for AKS**
   - Governance and compliance
   - Pod security policies
   - Image scanning enforcement

5. **Azure Monitor Application Insights**
   - Distributed tracing
   - Application-level metrics
   - Dependency mapping

6. **Azure DevOps / GitHub Actions for Applications**
   - CI/CD for containerized apps
   - Automated testing
   - GitOps with Flux or Argo CD

7. **Backup and Disaster Recovery**
   - Velero for AKS backup
   - Geo-redundant SQL backups
   - Multi-region deployment

### Scaling for Production

**Recommendations**:
- Upgrade SQL to Standard tier (S2 or higher)
- Upgrade ACR to Standard for geo-replication
- Add dedicated user node pool for application workloads
- Implement Pod Disruption Budgets
- Add Horizontal Pod Autoscaler
- Implement network policies
- Add Azure Firewall for egress control
- Enable Azure Defender for containers

---

**Document Version**: 1.0
**Last Updated**: 2025
**Author**: Infrastructure Team
