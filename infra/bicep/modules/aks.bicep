// ============================================================================
// Azure Kubernetes Service (AKS) Module
// ============================================================================
// This module creates a private AKS cluster for hosting the retail store's
// frontend (React) and backend (.NET) containers with auto-scaling enabled

@description('The name of the AKS cluster')
param aksClusterName string

@description('The location/region for the AKS cluster')
param location string = resourceGroup().location

@description('The Kubernetes version')
param kubernetesVersion string = '1.28.9'

@description('The DNS prefix for the AKS cluster')
param dnsPrefix string

@description('Enable private cluster')
param enablePrivateCluster bool = true

@description('The subnet ID for AKS nodes')
param aksSubnetId string

@description('The Log Analytics Workspace ID for monitoring')
param logAnalyticsWorkspaceId string

@description('The ACR ID for AKS to pull images from')
param acrId string

@description('The VM size for the node pool')
param nodeVmSize string = 'Standard_B2s'

@description('The minimum number of nodes for auto-scaling')
@minValue(1)
@maxValue(100)
param nodeCountMin int = 1

@description('The maximum number of nodes for auto-scaling')
@minValue(1)
@maxValue(100)
param nodeCountMax int = 3

@description('The initial number of nodes')
@minValue(1)
@maxValue(100)
param nodeCount int = 1

@description('The maximum number of pods per node')
@minValue(10)
@maxValue(250)
param maxPods int = 30

@description('Enable auto-scaling')
param enableAutoScaling bool = true

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Azure Kubernetes Service (AKS) Cluster
// ============================================================================
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: aksClusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: dnsPrefix
    kubernetesVersion: kubernetesVersion
    enableRBAC: true

    // Private cluster configuration
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
      enablePrivateClusterPublicFQDN: false
    }

    // Network configuration
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '10.1.0.0/16'
      dnsServiceIP: '10.1.0.10'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }

    // Default node pool (system node pool)
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: nodeCount
        vmSize: nodeVmSize
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetId
        enableAutoScaling: enableAutoScaling
        minCount: enableAutoScaling ? nodeCountMin : null
        maxCount: enableAutoScaling ? nodeCountMax : null
        maxPods: maxPods
        osDiskSizeGB: 30
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        enableNodePublicIP: false
      }
    ]

    // Add-ons configuration
    addonProfiles: {
      // Azure Monitor for containers
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      // Azure Policy
      azurepolicy: {
        enabled: false
      }
      // HTTP Application Routing (not recommended for production)
      httpApplicationRouting: {
        enabled: false
      }
    }

    // Auto-upgrade configuration
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }

    // Security configuration
    securityProfile: {
      defender: {
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
        securityMonitoring: {
          enabled: false // Can be enabled but adds cost
        }
      }
    }
  }
}

// ============================================================================
// Role Assignment - AKS to ACR
// ============================================================================
// Assign AcrPull role to AKS managed identity to pull images from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksCluster.id, acrId, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// Outputs
// ============================================================================
@description('The resource ID of the AKS cluster')
output aksClusterId string = aksCluster.id

@description('The name of the AKS cluster')
output aksClusterName string = aksCluster.name

@description('The FQDN of the AKS cluster')
output aksClusterFqdn string = aksCluster.properties.fqdn

@description('The AKS cluster managed identity principal ID')
output aksIdentityPrincipalId string = aksCluster.identity.principalId

@description('The AKS kubelet identity object ID')
output aksKubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId

@description('The AKS cluster API server address (private)')
output aksApiServerAddress string = enablePrivateCluster ? aksCluster.properties.privateFQDN : aksCluster.properties.fqdn
