// Fixed storageRoleAssignment.bicep
@description('The storage account resource ID')
param storageAccountId string

@description('The principal ID of the managed identity')
param principalId string

@description('The role definition ID for the Storage File Data SMB Share Contributor role')
param roleDefinitionId string = 'aba4ae5f-2193-4029-9191-0cb91df5e314' // Storage File Data SMB Share Contributor

// Extract the storage account name from the resource ID
var storageAccountName = split(storageAccountId, '/')[8]

// Reference the existing storage account resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

// Create the role assignment using the referenced resource for scope
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, principalId, roleDefinitionId)
  scope: storageAccount  // Use the resource reference instead of resourceId()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
