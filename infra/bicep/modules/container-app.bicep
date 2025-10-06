// ============================================================================
// Container App Module
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for resources')
param location string

@description('Container app name')
param containerAppName string

@description('Tags to apply to resources')
param tags object

@description('Container App Environment resource ID')
param environmentResourceId string

@description('ACR login server')
param acrLoginServer string

@description('ACR admin username')
param acrUsername string

@description('ACR admin password')
@secure()
param acrPassword string

@description('Container image name')
param containerImage string = 'nginx:latest'

@description('Container CPU allocation')
param containerCpu string = '0.25'

@description('Container memory allocation')
param containerMemory string = '0.5Gi'

@description('Target port for ingress')
param ingressTargetPort int = 80

@description('Enable external ingress')
param ingressExternal bool = true

@description('Ingress transport')
param ingressTransport string = 'auto'

@description('Allow insecure ingress')
param ingressAllowInsecure bool = false

@description('Minimum replicas')
param scaleMinReplicas int = 1

@description('Maximum replicas')
param scaleMaxReplicas int = 3

@description('Concurrent requests for scaling')
param scaleConcurrentRequests string = '10'

@description('Revision mode')
param activeRevisionsMode string = 'Single'

@description('Environment variables')
param environmentVariables array = [
  {
    name: 'DEBUG'
    value: 'False'
  }
]

// ============================================================================
// Container App using Azure Verified Module
// ============================================================================

module containerApp 'br/public:avm/res/app/container-app:0.11.0' = {
  name: '${uniqueString(deployment().name, location)}-container-app'
  params: {
    name: containerAppName
    location: location
    tags: tags
    environmentResourceId: environmentResourceId

    // Container configuration
    containers: [
      {
        name: containerAppName
        image: containerImage
        resources: {
          cpu: json(containerCpu)
          memory: containerMemory
        }
        env: environmentVariables
      }
    ]

    // Ingress configuration
    ingressExternal: ingressExternal
    ingressTargetPort: ingressTargetPort
    ingressTransport: ingressTransport
    ingressAllowInsecure: ingressAllowInsecure

    // Registry configuration
    registries: [
      {
        server: acrLoginServer
        username: acrUsername
        passwordSecretRef: 'acr-password'
      }
    ]

    // Secrets (using ACR admin credentials)
    secrets: {
      secureList: [
        {
          name: 'acr-password'
          value: acrPassword
        }
      ]
    }

    // Scale configuration
    scaleMinReplicas: scaleMinReplicas
    scaleMaxReplicas: scaleMaxReplicas
    scaleRules: [
      {
        name: 'http-rule'
        http: {
          metadata: {
            concurrentRequests: scaleConcurrentRequests
          }
        }
      }
    ]

    // Revision mode
    activeRevisionsMode: activeRevisionsMode
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Container app FQDN')
output fqdn string = containerApp.outputs.fqdn

@description('Container app URL')
output url string = 'https://${containerApp.outputs.fqdn}'

@description('Container app name')
output name string = containerApp.outputs.name

@description('Container app resource ID')
output resourceId string = containerApp.outputs.resourceId
