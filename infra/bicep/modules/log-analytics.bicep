// ============================================================================
// Log Analytics Workspace Module
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for resources')
param location string

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string

@description('Tags to apply to resources')
param tags object

@description('SKU name for Log Analytics workspace')
param skuName string = 'PerGB2018'

@description('Data retention in days')
param dataRetention int = 30

// ============================================================================
// Log Analytics Workspace using Azure Verified Module
// ============================================================================

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: '${uniqueString(deployment().name, location)}-log-analytics'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
    skuName: skuName
    dataRetention: dataRetention
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Log Analytics workspace ID')
output resourceId string = logAnalytics.outputs.resourceId

@description('Log Analytics workspace name')
output name string = logAnalytics.outputs.name

@description('Log Analytics workspace customer ID')
output customerId string = logAnalytics.outputs.logAnalyticsWorkspaceId
