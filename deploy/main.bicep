// Fixed main.bicep with no delay references
targetScope = 'subscription'

@description('The Azure region code for deployment resource group and resources such as westus, eastus, northcentralus, northeurope, etc...')
param location string = 'westeurope'

@description('The name of your search service. This value should be unique')
param applicationName string = 'meilisearch'

@description('The Container App CPU cores and Memory')
@allowed([
  {
    cpu: '0.5'
    memory: '1.0Gi'
  }
  {
    cpu: '0.75'
    memory: '1.5Gi'
  }
  {
    cpu: '1.0'
    memory: '2.0Gi'
  }
  {
    cpu: '1.25'
    memory: '2.50Gi'
  }
  {
    cpu: '1.5'
    memory: '3.0Gi'
  }
  {
    cpu: '1.75'
    memory: '3.5Gi'
  }
  {
    cpu: '2.0'
    memory: '4.0Gi'
  }
])
param containerResources object = {
  cpu: '1.0'
  memory: '2.0Gi'
}

@maxLength(4)
@description('The environment of deployment such as dev, test, stg, prod, etc...')
param deploymentEnvironment string = 'dev'

@secure()
@description('The Master API Key used to connect to Meilisearch instance')
@minLength(32)
param meilisearchMasterKey string = newGuid()

// We'll keep this parameter but not use it for role assignments
param useManagedIdentity bool = true

var resourceGroupName = '${applicationName}-${deploymentEnvironment}-rg'
var logAnalyticsWorkspaceResName = '${applicationName}-${deploymentEnvironment}-logs'
var environmentName = '${applicationName}-${deploymentEnvironment}-env'
var storageAccountName = '${take(applicationName,14)}${deploymentEnvironment}strg'

var shareName = 'meilisearch-fileshare'
var storageNameMount = 'permanent-storage-mount'

var meilisearchImageName = 'getmeili/meilisearch:v0.29'
var meilisearchAppPort = 7700
var dbMountPath = '/data/meili'
var volumeName = 'azure-file-volume'

var defaultTags = {
  environment: deploymentEnvironment
  application: applicationName
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: defaultTags
}

// Module deployments
module logAnalyticsWorkspace 'modules/logAnalyticsWorkspace.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${deployment().name}--logAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceResName
    location: rg.location
    resourceTags: defaultTags
  }
}

// Create the Container App Environment with managed identity
module environment 'modules/acaEnvironment.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${deployment().name}--acaenvironment'
  params: {
    acaEnvironmentName: environmentName
    location: rg.location
    logAnalyticsWorkspaceCustomerId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceCustomerId
    logAnalyticsWorkspacePrimarySharedKey: logAnalyticsWorkspace.outputs.logAnalyticsWorkspacePrimarySharedKey
    resourceTags: defaultTags
    enableManagedIdentity: useManagedIdentity
  }
}

// Create the storage account with secure settings but no resource access rules
module storageModule 'modules/storage.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${deployment().name}--storage'
  params: {
    storageAccountName: storageAccountName
    location: rg.location
    applicationName: applicationName
    containerName: applicationName
    shareName: shareName
    resourceTags: defaultTags
  }
}

// Create the storage mount on the Container App Environment using storage keys
module environmentStorages 'modules/acaEnvironmentStorages.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${deployment().name}--acaenvironmentstorages'
  params: {
    acaEnvironmentName: environmentName
    storageAccountResName: storageModule.outputs.storageAccountName
    storageAccountResourceKey: storageModule.outputs.storageKey
    storageNameMount: storageNameMount
    shareName: shareName
  }
  dependsOn: [
    environment
    storageModule
  ]
}

// Deploy the Container App with dependency on the storage mount
module containerApp 'modules/containerApp.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${deployment().name}--${applicationName}'
  params: {
    containerAppName: applicationName
    location: rg.location
    environmentId: environment.outputs.acaEnvironmentId
    containerImage: meilisearchImageName
    targetPort: meilisearchAppPort
    minReplicas: 1
    maxReplicas: 1
    revisionMode: 'Single'
    storageNameMount: storageNameMount
    mountPath: dbMountPath
    volumeName: volumeName
    resourceTags: defaultTags
    resourceAllocationCPU: containerResources.cpu
    resourceAllocationMemory: containerResources.memory
    secListObj: {
      secArray: [
        {
          name: 'meili-master-key-value'
          value: meilisearchMasterKey
        }
      ]
    }
    envList: [
      {
        name: 'MEILI_MASTER_KEY'
        secretRef: 'meili-master-key-value'
      }
      {
        name: 'MEILI_DB_PATH'
        value: dbMountPath
      }
    ]
  }
  dependsOn: [
    environmentStorages
  ]
}

output containerAppUrl string = containerApp.outputs.fqdn
