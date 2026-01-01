// ============================================================================
// Monitoring Module - Log Analytics Workspace
// ============================================================================
// This module creates a Log Analytics Workspace for monitoring the AKS cluster,
// container logs, and application insights

@description('The name of the Log Analytics Workspace')
param workspaceName string

@description('The location/region for the workspace')
param location string = resourceGroup().location

@description('The SKU for Log Analytics Workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
])
param sku string = 'PerGB2018'

@description('Data retention in days (30-730 days for paid, 7 days for free)')
@minValue(7)
@maxValue(730)
param retentionInDays int = 30

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Log Analytics Workspace
// ============================================================================
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// Container Insights Solution
// ============================================================================
// This solution enables Container Insights for AKS monitoring
resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  plan: {
    name: 'ContainerInsights(${logAnalyticsWorkspace.name})'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ============================================================================
// Outputs
// ============================================================================
@description('The resource ID of the Log Analytics Workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('The name of the Log Analytics Workspace')
output workspaceName string = logAnalyticsWorkspace.name

@description('The workspace ID (customer ID) for agents')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('The primary shared key for the workspace')
output workspacePrimaryKey string = logAnalyticsWorkspace.listKeys().primarySharedKey
