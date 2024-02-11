@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // This is the Storage Account Contributor role, which is the minimum role permission we can give. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#:~:text=17d1049b-9a84-46fb-8f53-869881c3d3ab
  name: '86e8f5dc-a6e9-4c67-9d15-de283e8eac25'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${projectName}${environment}${shortLocation}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'DeploymentScript'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(resourceGroup().id, managedIdentity.id, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deploymentScript'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    // we need to ensure we wait for the role assignment to be deployed before trying to access the storage account
    roleAssignment
  ]
  properties: {
    azPowerShellVersion: '3.0'
    scriptContent: loadTextContent('./scripts/enable-static-website.ps1')
    retentionInterval: 'PT4H'
    environmentVariables: [
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'StorageAccountName'
        value: storageAccount.name
      }
      {
        name: 'IndexDocumentPath'
        value: 'index.html'
      }
      {
        name: 'ErrorDocument404Path'
        value: 'index.html'
      }
      {
        name: 'ErrorDocument404Contents'
        value: 'index.html'
      }
    ]
  }
}

resource kvStorageAccountConnString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-StorageAccount'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
  }
}

output storageAccountSecretUri string = kvStorageAccountConnString.properties.secretUri
