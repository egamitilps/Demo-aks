// ============================================================================
// Development Environment Parameters
// ============================================================================
// This parameter file contains development environment-specific values
// for deploying the retail store infrastructure
//
// IMPORTANT: This file contains placeholder values for sensitive data.
// Update these values before deployment or use Azure Key Vault references.
// ============================================================================

using '../main.bicep'

// ============================================================================
// Environment Configuration
// ============================================================================
param environment = 'dev'
param projectName = 'retail'
param location = 'southcentralus'

// ============================================================================
// SQL Database Configuration
// ============================================================================
// ⚠️  SECURITY WARNING: Do not commit actual passwords to source control!
// Use one of these methods instead:
//   1. Pass as parameter during deployment: --parameters sqlAdminPassword=$PASSWORD
//   2. Use Azure Key Vault reference (recommended)
//   3. Use environment variables in CI/CD pipeline

param sqlAdminUsername = 'sqladmin'

// TODO: Replace with actual password or Key Vault reference before deployment
// Example Key Vault reference (uncomment and update):
// param sqlAdminPassword = az.getSecret('key-vault-name', 'sql-admin-password')

// For local testing only (replace with secure method):
param sqlAdminPassword = 'P@ssw0rd123!' // ⚠️  CHANGE THIS!

// ============================================================================
// Feature Flags
// ============================================================================
// Application Gateway for Containers is disabled by default to save cost
// Set to true when ready to spend additional $70-100/month
param enableAppGatewayForContainers = false

// ============================================================================
// Resource Tags
// ============================================================================
param tags = {
  Environment: 'Development'
  Project: 'Retail Store'
  ManagedBy: 'Bicep'
  CostCenter: 'Engineering'
  Owner: 'DevTeam'
  DeployedBy: 'Azure DevOps' // or 'GitHub Actions'
}
