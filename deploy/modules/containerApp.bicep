// Fixed containerApp.bicep
@description('The name of the ACA container app')
param containerAppName string

@description('The Azure region for resources')
param location string

@description('Resource tags to apply')
param resourceTags object

@description('Container App Environment ID')
param environmentId string

@description('Container image to deploy')
param containerImage string

@description('Port to expose')
param targetPort int

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 1

@description('Revision mode: Multiple or Single')
@allowed([
  'Multiple'
  'Single'
])
param revisionMode string = 'Single'

@description('The name of the storage mount')
param storageNameMount string

@description('The mount path in container')
param mountPath string

@description('The volume name')
param volumeName string

@description('Resource allocation for CPU cores')
param resourceAllocationCPU string

@description('Resource allocation for memory')
param resourceAllocationMemory string

@description('List of environment variables')
param envList array = []

@description('Secret list object')
@secure()
param secListObj object

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: containerAppName
  location: location
  tags: resourceTags
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: revisionMode
      secrets: secListObj.secArray
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: containerAppName
          env: envList
          volumeMounts: [
            {
              volumeName: volumeName
              mountPath: mountPath
            }
          ]
          resources: {
            cpu: json(resourceAllocationCPU)
            memory: resourceAllocationMemory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
      volumes: [
        {
          name: volumeName
          storageName: storageNameMount
          storageType: 'AzureFile'
        }
      ]
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
