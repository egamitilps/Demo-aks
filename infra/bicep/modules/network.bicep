// ============================================================================
// Network Module - Virtual Network and Subnets
// ============================================================================
// This module creates the virtual network infrastructure for the retail store application
// including subnets for AKS, Application Gateway, and private endpoints

@description('The name of the virtual network')
param vnetName string

@description('The location/region for the virtual network')
param location string = resourceGroup().location

@description('The address prefix for the virtual network (CIDR notation)')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('The address prefix for the AKS subnet')
param aksSubnetAddressPrefix string = '10.0.1.0/24'

@description('The address prefix for the Application Gateway subnet')
param appGwSubnetAddressPrefix string = '10.0.2.0/24'

@description('The address prefix for the private endpoints subnet')
param privateEndpointsSubnetAddressPrefix string = '10.0.3.0/24'

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Virtual Network
// ============================================================================
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      // Subnet for AKS cluster nodes
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: aksSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      // Subnet for Application Gateway for Containers (Azure-native ingress)
      {
        name: 'appgw-subnet'
        properties: {
          addressPrefix: appGwSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          delegations: [
            {
              name: 'Microsoft.ServiceNetworking/trafficControllers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
        }
      }
      // Subnet for private endpoints (ACR, SQL Database)
      {
        name: 'private-endpoints-subnet'
        properties: {
          addressPrefix: privateEndpointsSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================
@description('The resource ID of the virtual network')
output vnetId string = vnet.id

@description('The name of the virtual network')
output vnetName string = vnet.name

@description('The resource ID of the AKS subnet')
output aksSubnetId string = vnet.properties.subnets[0].id

@description('The name of the AKS subnet')
output aksSubnetName string = vnet.properties.subnets[0].name

@description('The resource ID of the Application Gateway subnet')
output appGwSubnetId string = vnet.properties.subnets[1].id

@description('The name of the Application Gateway subnet')
output appGwSubnetName string = vnet.properties.subnets[1].name

@description('The resource ID of the private endpoints subnet')
output privateEndpointsSubnetId string = vnet.properties.subnets[2].id

@description('The name of the private endpoints subnet')
output privateEndpointsSubnetName string = vnet.properties.subnets[2].name
