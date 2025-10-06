// ============================================================================
// Container Apps Environment Module
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for resources')
param location string

@description('Container app environment name')
param containerAppEnvironmentName string

@description('Tags to apply to resources')
param tags object

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceResourceId string

@description('Workload profiles configuration')
param workloadProfiles array = [
  {
    name: 'Consumption'
    workloadProfileType: 'Consumption'
  }
]

// ============================================================================
// Container Apps Environment using Azure Verified Module
// ============================================================================

module containerAppEnvironment 'br/public:avm/res/app/managed-environment:0.8.2' = {
  name: '${uniqueString(deployment().name, location)}-container-app-env'
  params: {
    name: containerAppEnvironmentName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    workloadProfiles: workloadProfiles
    zoneRedundant: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Container App Environment ID')
output resourceId string = containerAppEnvironment.outputs.resourceId

@description('Container App Environment name')
output name string = containerAppEnvironment.outputs.name

@description('Container App Environment default domain')
output defaultDomain string = containerAppEnvironment.outputs.defaultDomain
