// storage-role-assignment.bicep - Modified to use an allowed role
@description('The storage account resource ID')
param storageAccountId string

@description('The principal ID of the managed identity')
param principalId string

// Use Storage Account Contributor role which should be allowed in your environment
@description('The role definition ID for the Storage Account Contributor role')
param roleDefinitionId string = '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor role

// Extract the storage account name from the resource ID
var storageAccountName = split(storageAccountId, '/')[8]

// Reference the existing storage account resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

// Create the role assignment using the referenced resource for scope
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, principalId, roleDefinitionId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Output the role assignment ID
output roleAssignmentId string = roleAssignment.id
