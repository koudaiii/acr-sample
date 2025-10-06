// ============================================================================
// Azure Container Registry Module
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for resources')
param location string

@description('Azure Container Registry name (must be globally unique)')
param acrName string

@description('Tags to apply to resources')
param tags object

@description('ACR SKU')
param acrSku string = 'Basic'

@description('Enable ACR admin user')
param acrAdminUserEnabled bool = true

@description('Public network access setting')
param publicNetworkAccess string = 'Enabled'

// ============================================================================
// Azure Container Registry using Azure Verified Module
// ============================================================================

module containerRegistry 'br/public:avm/res/container-registry/registry:0.7.1' = {
  name: '${uniqueString(deployment().name, location)}-acr'
  params: {
    name: acrName
    location: location
    tags: tags
    acrSku: acrSku
    acrAdminUserEnabled: acrAdminUserEnabled
    publicNetworkAccess: publicNetworkAccess
  }
}

// ============================================================================
// Get ACR credentials using existing resource
// ============================================================================

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
  dependsOn: [
    containerRegistry
  ]
}

// ============================================================================
// Outputs
// ============================================================================

@description('ACR login server')
output loginServer string = containerRegistry.outputs.loginServer

@description('ACR name')
output name string = containerRegistry.outputs.name

@description('ACR resource ID')
output resourceId string = containerRegistry.outputs.resourceId

@description('ACR admin username')
output adminUsername string = acr.listCredentials().username

@description('ACR admin password')
output adminPassword string = acr.listCredentials().passwords[0].value
