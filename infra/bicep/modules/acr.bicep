// ============================================================================
// Azure Container Registry Module
// ============================================================================
// This module creates an Azure Container Registry for storing Docker images
// for the retail store's frontend (React) and backend (.NET) applications

@description('The name of the Azure Container Registry')
param acrName string

@description('The location/region for the ACR')
param location string = resourceGroup().location

@description('The SKU for ACR (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Enable admin user for ACR (not recommended for production)')
param adminUserEnabled bool = false

@description('Enable public network access')
param publicNetworkAccess string = 'Disabled'

@description('The subnet ID for private endpoint')
param privateEndpointSubnetId string

@description('The virtual network ID for private DNS zone')
param vnetId string

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Azure Container Registry
// ============================================================================
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: publicNetworkAccess
    networkRuleBypassOptions: 'AzureServices'
  }
}

// ============================================================================
// Private DNS Zone for ACR
// ============================================================================
resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: tags
}

// Link Private DNS Zone to Virtual Network
resource acrPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: acrPrivateDnsZone
  name: '${acrName}-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// ============================================================================
// Private Endpoint for ACR
// ============================================================================
resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${acrName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${acrName}-pl-connection'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for ACR Private Endpoint
resource acrPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: acrPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateDnsZoneId: acrPrivateDnsZone.id
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================
@description('The resource ID of the Azure Container Registry')
output acrId string = acr.id

@description('The name of the Azure Container Registry')
output acrName string = acr.name

@description('The login server URL for the ACR')
output acrLoginServer string = acr.properties.loginServer

@description('The resource ID of the ACR private endpoint')
output acrPrivateEndpointId string = acrPrivateEndpoint.id
