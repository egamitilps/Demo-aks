// ============================================================================
// Application Gateway for Containers Module (FUTURE USE)
// ============================================================================
// ⚠️  NOT DEPLOYED IN CURRENT PIPELINE - FOR FUTURE USE ONLY ⚠️
//
// This module creates Azure Application Gateway for Containers (ALB Controller)
// which is the next-generation ingress solution for AKS.
//
// COST WARNING: This resource costs approximately $70-100/month
// Currently using NGINX Ingress Controller (free) to stay within budget
//
// To use this in the future:
// 1. Uncomment the module reference in main.bicep
// 2. Update the deployment pipeline to include this module
// 3. Ensure budget allows for additional $70-100/month cost
// 4. Install the ALB Controller in your AKS cluster
// ============================================================================

@description('The name of the Application Gateway for Containers')
param appGwName string

@description('The location/region for the Application Gateway')
param location string = resourceGroup().location

@description('The subnet ID for Application Gateway for Containers')
param appGwSubnetId string

@description('The AKS cluster name for association')
param aksClusterName string

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Managed Identity for Application Gateway for Containers
// ============================================================================
// This identity is used by the ALB Controller to manage the Application Gateway
resource appGwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${appGwName}-identity'
  location: location
  tags: tags
}

// ============================================================================
// Application Load Balancer (Application Gateway for Containers)
// ============================================================================
// Note: This uses the Microsoft.ServiceNetworking provider (preview/GA)
resource applicationLoadBalancer 'Microsoft.ServiceNetworking/trafficControllers@2023-11-01' = {
  name: appGwName
  location: location
  tags: tags
  properties: {}
}

// ============================================================================
// Application Load Balancer Frontend
// ============================================================================
// This creates the frontend configuration for the ALB
resource albFrontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2023-11-01' = {
  parent: applicationLoadBalancer
  name: 'default-frontend'
  location: location
  properties: {}
}

// ============================================================================
// Association with Subnet
// ============================================================================
// Links the ALB to the delegated subnet
resource albAssociation 'Microsoft.ServiceNetworking/trafficControllers/associations@2023-11-01' = {
  parent: applicationLoadBalancer
  name: 'subnet-association'
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: appGwSubnetId
    }
  }
}

// ============================================================================
// INSTRUCTIONS FOR FUTURE DEPLOYMENT
// ============================================================================
// After deploying this Bicep module, you need to install the ALB Controller
// in your AKS cluster. Run these commands:
//
// 1. Get AKS credentials:
//    az aks get-credentials --name <aks-cluster-name> --resource-group <rg-name>
//
// 2. Install the ALB Controller using Helm:
//    helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
//      --version 1.0.0 \
//      --set albControllerIdentity.clientId=<managed-identity-client-id> \
//      --set albControllerIdentity.resourceId=<managed-identity-resource-id> \
//      --namespace kube-system
//
// 3. Create an ApplicationLoadBalancer resource in Kubernetes:
//    kubectl apply -f - <<EOF
//    apiVersion: alb.networking.azure.io/v1
//    kind: ApplicationLoadBalancer
//    metadata:
//      name: alb
//      namespace: default
//    spec:
//      associations:
//      - <alb-resource-id>
//    EOF
//
// 4. Configure your Ingress resources to use the ALB Controller:
//    kubernetes.io/ingress.class: azure-alb
//
// For detailed instructions, see:
// https://learn.microsoft.com/azure/application-gateway/for-containers/
// ============================================================================

// ============================================================================
// Outputs
// ============================================================================
@description('The resource ID of the Application Gateway for Containers')
output albId string = applicationLoadBalancer.id

@description('The name of the Application Gateway for Containers')
output albName string = applicationLoadBalancer.name

@description('The resource ID of the ALB frontend')
output albFrontendId string = albFrontend.id

@description('The resource ID of the managed identity for ALB Controller')
output albIdentityId string = appGwIdentity.id

@description('The client ID of the managed identity for ALB Controller')
output albIdentityClientId string = appGwIdentity.properties.clientId

@description('The principal ID of the managed identity for ALB Controller')
output albIdentityPrincipalId string = appGwIdentity.properties.principalId

// ============================================================================
// COST ESTIMATE
// ============================================================================
// Estimated monthly cost (South Central US):
// - Application Gateway for Containers: ~$70-100/month
//   * Base capacity units
//   * Data processing charges
//   * Standard tier pricing
//
// Total estimated cost: ~$70-100/month
//
// This is in ADDITION to your other infrastructure costs
// ============================================================================
