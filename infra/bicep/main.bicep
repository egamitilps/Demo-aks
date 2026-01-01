// ============================================================================
// Main Orchestration Template - Retail Store AKS Infrastructure
// ============================================================================
// This is the main Bicep template that orchestrates the deployment of all
// infrastructure components for the retail store three-tier application:
//   - Presentation Tier: React frontend (running in AKS)
//   - Logic Tier: .NET API (business logic, running in AKS)
//   - Data Tier: Azure SQL Database (separate managed service)
//
// Infrastructure Components:
//   ✓ Virtual Network with subnets
//   ✓ Azure Kubernetes Service (private cluster with auto-scaling)
//   ✓ Azure Container Registry (private)
//   ✓ Azure SQL Database (private)
//   ✓ Application Gateway for Containers (Azure-native ingress)
//   ✓ Log Analytics Workspace for monitoring
//   ✓ Private endpoints for secure connectivity
//
// Azure-Native Approach:
//   - Using Application Gateway for Containers (fully managed Azure ingress)
//   - All infrastructure is Azure PaaS/managed services
//   - Estimated monthly cost: $129-224
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('The Azure region for all resources')
param location string = resourceGroup().location

@description('The environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('The project name (used for resource naming)')
@minLength(3)
@maxLength(10)
param projectName string = 'retail'

@description('The administrator username for SQL Server')
param sqlAdminUsername string

@description('The administrator password for SQL Server')
@secure()
param sqlAdminPassword string

@description('Enable Application Gateway for Containers (Azure-native ingress, adds ~$70-100/month)')
param enableAppGatewayForContainers bool = true

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
  CostCenter: 'Development'
}

// ============================================================================
// Variables for Resource Naming
// ============================================================================

var uniqueSuffix = uniqueString(resourceGroup().id)
var namingPrefix = '${projectName}-${environment}'

// Resource names
var vnetName = '${namingPrefix}-vnet'
var aksClusterName = '${namingPrefix}-aks-${uniqueSuffix}'
var acrName = '${projectName}${environment}acr${uniqueSuffix}' // Must be globally unique, alphanumeric only
var sqlServerName = '${namingPrefix}-sql-${uniqueSuffix}' // Must be globally unique
var sqlDatabaseName = '${projectName}DB'
var logAnalyticsName = '${namingPrefix}-logs-${uniqueSuffix}'
var appGwName = '${namingPrefix}-appgw-${uniqueSuffix}'

// ============================================================================
// Module: Monitoring (Log Analytics Workspace)
// ============================================================================
// Deploy this first as AKS depends on it
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    workspaceName: logAnalyticsName
    location: location
    sku: 'PerGB2018'
    retentionInDays: 30
    tags: tags
  }
}

// ============================================================================
// Module: Network (Virtual Network and Subnets)
// ============================================================================
module network './modules/network.bicep' = {
  name: 'network-deployment'
  params: {
    vnetName: vnetName
    location: location
    vnetAddressPrefix: '10.0.0.0/16'
    aksSubnetAddressPrefix: '10.0.1.0/24'
    appGwSubnetAddressPrefix: '10.0.2.0/24'
    privateEndpointsSubnetAddressPrefix: '10.0.3.0/24'
    tags: tags
  }
}

// ============================================================================
// Module: Azure Container Registry (ACR)
// ============================================================================
module acr './modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    acrSku: 'Basic'
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    privateEndpointSubnetId: network.outputs.privateEndpointsSubnetId
    vnetId: network.outputs.vnetId
    tags: tags
  }
}

// ============================================================================
// Module: Azure SQL Database
// ============================================================================
module sql './modules/sql.bicep' = {
  name: 'sql-deployment'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    location: location
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword
    skuName: 'Basic'
    tier: 'Basic'
    maxSizeBytes: 2147483648 // 2 GB
    publicNetworkAccess: 'Disabled'
    privateEndpointSubnetId: network.outputs.privateEndpointsSubnetId
    vnetId: network.outputs.vnetId
    tags: tags
  }
}

// ============================================================================
// Module: Azure Kubernetes Service (AKS)
// ============================================================================
module aks './modules/aks.bicep' = {
  name: 'aks-deployment'
  params: {
    aksClusterName: aksClusterName
    location: location
    kubernetesVersion: '1.28.9'
    dnsPrefix: '${namingPrefix}-dns'
    enablePrivateCluster: true
    aksSubnetId: network.outputs.aksSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    acrId: acr.outputs.acrId
    nodeVmSize: 'Standard_B2s'
    nodeCountMin: 1
    nodeCountMax: 3
    nodeCount: 1
    maxPods: 30
    enableAutoScaling: true
    tags: tags
  }
}

// ============================================================================
// Module: Application Gateway for Containers (Azure-Native Ingress)
// ============================================================================
// Azure's fully-managed ingress solution for AKS
// Provides advanced routing, WAF capabilities, and native Azure integration
module appGatewayForContainers './modules/appgw-containers.bicep' = if (enableAppGatewayForContainers) {
  name: 'appgw-deployment'
  params: {
    appGwName: appGwName
    location: location
    appGwSubnetId: network.outputs.appGwSubnetId
    aksClusterName: aks.outputs.aksClusterName
    tags: tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

// Network Outputs
@description('The resource ID of the virtual network')
output vnetId string = network.outputs.vnetId

@description('The name of the virtual network')
output vnetName string = network.outputs.vnetName

// AKS Outputs
@description('The resource ID of the AKS cluster')
output aksClusterId string = aks.outputs.aksClusterId

@description('The name of the AKS cluster')
output aksClusterName string = aks.outputs.aksClusterName

@description('Command to get AKS credentials')
output aksGetCredentialsCommand string = 'az aks get-credentials --name ${aks.outputs.aksClusterName} --resource-group ${resourceGroup().name}'

// ACR Outputs
@description('The resource ID of the Azure Container Registry')
output acrId string = acr.outputs.acrId

@description('The name of the Azure Container Registry')
output acrName string = acr.outputs.acrName

@description('The login server URL for ACR')
output acrLoginServer string = acr.outputs.acrLoginServer

@description('Command to login to ACR')
output acrLoginCommand string = 'az acr login --name ${acr.outputs.acrName}'

// SQL Database Outputs
@description('The resource ID of the SQL Server')
output sqlServerId string = sql.outputs.sqlServerId

@description('The name of the SQL Server')
output sqlServerName string = sql.outputs.sqlServerName

@description('The name of the SQL Database')
output sqlDatabaseName string = sql.outputs.sqlDatabaseName

@description('The SQL Server FQDN')
output sqlServerFqdn string = sql.outputs.sqlServerFqdn

// Monitoring Outputs
@description('The resource ID of the Log Analytics Workspace')
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId

@description('The name of the Log Analytics Workspace')
output logAnalyticsWorkspaceName string = monitoring.outputs.workspaceName

// Application Gateway Outputs
@description('The resource ID of the Application Gateway for Containers')
output appGatewayId string = enableAppGatewayForContainers ? appGatewayForContainers.outputs.albId : ''

@description('The name of the Application Gateway for Containers')
output appGatewayName string = enableAppGatewayForContainers ? appGatewayForContainers.outputs.albName : ''

@description('The managed identity client ID for ALB Controller')
output appGatewayIdentityClientId string = enableAppGatewayForContainers ? appGatewayForContainers.outputs.albIdentityClientId : ''

// ============================================================================
// Next Steps (displayed as outputs)
// ============================================================================
@description('Next steps after deployment')
output nextSteps string = '''
=================================================
🎉 Infrastructure Deployment Complete!
=================================================

Next Steps:

1. Connect to AKS:
   ${aksGetCredentialsCommand}

2. Install Application Gateway for Containers (ALB) Controller:
   helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
     --version 1.0.0 \
     --set albController.namespace=azure-alb-system \
     --namespace azure-alb-system \
     --create-namespace

   See docs/deployment-guide.md for detailed ALB configuration

3. Create Kubernetes secret for SQL connection:
   kubectl create secret generic sql-connection-string \
     --from-literal=connection-string="Server=${sqlServerFqdn};Database=${sqlDatabaseName};User Id=${sqlAdminUsername};Password=<your-password>"

4. Build and push your container images:
   ${acrLoginCommand}
   docker build -t ${acrLoginServer}/frontend:latest ./src/frontend
   docker build -t ${acrLoginServer}/logic-tier:latest ./src/logic-tier
   docker push ${acrLoginServer}/frontend:latest
   docker push ${acrLoginServer}/logic-tier:latest

5. Deploy your applications to AKS (create deployments and services)

For detailed deployment guide, see: docs/deployment-guide.md
=================================================
'''
