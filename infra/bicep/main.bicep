// ============================================================================
// ACR Sample - Infrastructure as Code (Bicep)
// Using Azure Verified Modules (AVM)
// ============================================================================

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for resources')
param location string = 'japaneast'

@description('Suffix to append to resource names for uniqueness')
param suffix string = dateTimeAdd(utcNow(), 'PT0H', 'yyyyMMddHHmmss')

@description('Resource group name')
param resourceGroupName string = 'acr-sample-rg'

@description('Azure Container Registry name (must be globally unique)')
@minLength(5)
@maxLength(50)
param acrName string = 'acrsamplekoudaiii'

@description('Container app name')
param containerAppName string = 'acr-sample-app'

@description('Container app environment name')
param containerAppEnvironmentName string = 'acr-sample-env'

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = 'acr-sample-logs'

@description('Tags to apply to resources')
param tags object = {
  environment: 'production'
  project: 'acr-sample'
  managed_by: 'bicep'
}

// ============================================================================
// Resource Group using Azure Verified Module
// ============================================================================

module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: '${uniqueString(deployment().name, location)}-resource-group'
  params: {
    name: '${resourceGroupName}${suffix}'
    location: location
    tags: tags
  }
}

// ============================================================================
// All resources deployed via decomposed modules
// ============================================================================

module resources './resources.bicep' = {
  name: '${uniqueString(deployment().name, location)}-resources'
  scope: az.resourceGroup('${resourceGroupName}${suffix}')
  params: {
    location: location
    acrName: '${acrName}${suffix}'
    containerAppName: '${containerAppName}${suffix}'
    containerAppEnvironmentName: '${containerAppEnvironmentName}${suffix}'
    logAnalyticsWorkspaceName: '${logAnalyticsWorkspaceName}${suffix}'
    tags: tags
  }
  dependsOn: [
    resourceGroup
  ]
}

// ============================================================================
// Outputs
// ============================================================================

@description('Resource group name')
output resourceGroupName string = resourceGroup.outputs.name

@description('ACR login server')
output acrLoginServer string = resources.outputs.acrLoginServer

@description('ACR name')
output acrName string = resources.outputs.acrName

@description('Container app FQDN')
output containerAppFqdn string = resources.outputs.containerAppFqdn

@description('Container app URL')
output containerAppUrl string = resources.outputs.containerAppUrl

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = resources.outputs.logAnalyticsWorkspaceId

@description('Container App Environment ID')
output containerAppEnvironmentId string = resources.outputs.containerAppEnvironmentId
