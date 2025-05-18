// Updated acaEnvironmentStorages.bicep
@description('The name of Azure Container Apps Environment')
param acaEnvironmentName string

@description('The name of your storage account')
param storageAccountResName string

@description('The storage account key')
@secure()
param storageAccountResourceKey string

@description('The ACA env storage name mount')
param storageNameMount string

@description('The name of the Azure file share')
param shareName string

// Note: We've removed the useManagedIdentity parameter since it's not supported by Container Apps for storage mounts

resource acaEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: acaEnvironmentName
}

// Create the storage mount always using the account key
resource storageMount 'Microsoft.App/managedEnvironments/storages@2022-03-01' = {
  name: storageNameMount
  parent: acaEnvironment
  properties: {
    azureFile: {
      accountName: storageAccountResName
      accountKey: storageAccountResourceKey
      shareName: shareName
      accessMode: 'ReadWrite'
    }
  }
}
