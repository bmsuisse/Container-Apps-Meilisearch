// Fixed acaEnvironmentStorages.bicep
@description('The name of Azure Container Apps Environment')
param acaEnvironmentName string

@description('The name of your storage account')
param storageAccountResName string

@description('The storage account key - only used if not using managed identity')
@secure()
param storageAccountResourceKey string = ''

@description('The ACA env storage name mount')
param storageNameMount string

@description('The name of the Azure file share')
param shareName string

@description('Use managed identity for storage access instead of keys')
param useManagedIdentity bool = true

resource acaEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: acaEnvironmentName
}

// Create the storage mount using managed identity
resource storageMount 'Microsoft.App/managedEnvironments/storages@2022-03-01' = {
  name: storageNameMount
  parent: acaEnvironment
  properties: {
    azureFile: {
      accountName: storageAccountResName
      accountKey: useManagedIdentity ? null : storageAccountResourceKey
      shareName: shareName
      accessMode: 'ReadWrite'
    }
  }
}
