// ============================================================================
// Resource-scoped resources module
// All Azure resources deployed at resource group scope
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for resources')
param location string

@description('Azure Container Registry name (must be globally unique)')
param acrName string

@description('Container app name')
param containerAppName string

@description('Container app environment name')
param containerAppEnvironmentName string

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string

@description('Tags to apply to resources')
param tags object

// Log Analytics Workspace
module logAnalytics './modules/log-analytics.bicep' = {
  name: '${uniqueString(deployment().name, location)}-log-analytics'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    tags: tags
  }
}

// Azure Container Registry
module containerRegistry './modules/container-registry.bicep' = {
  name: '${uniqueString(deployment().name, location)}-container-registry'
  params: {
    location: location
    acrName: acrName
    tags: tags
  }
}

// Container Apps Environment
module containerAppEnvironment './modules/container-app-environment.bicep' = {
  name: '${uniqueString(deployment().name, location)}-container-app-environment'
  params: {
    location: location
    containerAppEnvironmentName: containerAppEnvironmentName
    tags: tags
    logAnalyticsWorkspaceResourceId: logAnalytics.outputs.resourceId
  }
}

// Container App
module containerApp './modules/container-app.bicep' = {
  name: '${uniqueString(deployment().name, location)}-container-app'
  params: {
    location: location
    containerAppName: containerAppName
    tags: tags
    environmentResourceId: containerAppEnvironment.outputs.resourceId
    acrLoginServer: containerRegistry.outputs.loginServer
    acrUsername: containerRegistry.outputs.adminUsername
    acrPassword: containerRegistry.outputs.adminPassword
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('ACR login server')
output acrLoginServer string = containerRegistry.outputs.loginServer

@description('ACR name')
output acrName string = containerRegistry.outputs.name

@description('Container app FQDN')
output containerAppFqdn string = containerApp.outputs.fqdn

@description('Container app URL')
output containerAppUrl string = 'https://${containerApp.outputs.fqdn}'

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.resourceId

@description('Container App Environment ID')
output containerAppEnvironmentId string = containerAppEnvironment.outputs.resourceId
