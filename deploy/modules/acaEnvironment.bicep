// Fixed acaEnvironment.bicep
@description('The name of Azure Container Apps Environment')
param acaEnvironmentName string

@description('The Azure region for resources')
param location string = resourceGroup().location

@description('Resource tags to apply')
param resourceTags object

@description('Log Analytics Customer ID')
param logAnalyticsWorkspaceCustomerId string

@description('Log Analytics Primary Shared Key')
@secure()
param logAnalyticsWorkspacePrimarySharedKey string

@description('Enable system-assigned managed identity')
param enableManagedIdentity bool = true

resource acaEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: acaEnvironmentName
  location: location
  tags: resourceTags
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceCustomerId
        sharedKey: logAnalyticsWorkspacePrimarySharedKey
      }
    }
  }
}

output acaEnvironmentId string = acaEnvironment.id
// Output the principal ID of the managed identity if enabled
output principalId string = enableManagedIdentity ? acaEnvironment.identity.principalId : ''
