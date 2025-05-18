@description('The name of your application')
param applicationName string

@description('The Azure region where all resources in this example should be created')
param location string = resourceGroup().location

@description('A list of tags to apply to the resources')
param resourceTags object

@description('The name of the container to create. Defaults to applicationName value.')
param containerName string = applicationName

@description('The name of the Azure file share.')
param shareName string

@description('The name of storage account')
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  tags: resourceTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false  // Explicitly set to false to comply with policy
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: []
      ipRules: []
    }
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: containerName
  parent: blobServices
  properties: {
    publicAccess: 'None'  // Explicitly set container to no public access
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource permanentFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = {
  name: shareName
  parent: fileServices
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
    shareQuota: 1024
  }
}

// Note: For use in secure environments, this key should be passed to a Key Vault
// instead of being exposed as an output. The key is kept here for compatibility
// with existing code but should be treated as sensitive.
var storageKeyValue = storageAccount.listKeys().keys[0].value

output storageAccountName string = storageAccount.name
output id string = storageAccount.id
output apiVersion string = storageAccount.apiVersion
@secure()
output storageKey string = storageKeyValue
