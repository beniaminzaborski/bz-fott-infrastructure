@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: 'sb-${projectName}-${environment}-${shortLocation}'
  location: location
  sku: {
    name: 'Standard'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

// resource serviveBusNamespaceAuthRules 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
//   name: 'AppManage'
//   parent: serviceBusNamespace
//   properties: {
//     rights: [
//       'Manage'
//     ]
//   }
// }

var serviceBusNamespaceAuthRuleEndpoint = '${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnString = listKeys(serviceBusNamespaceAuthRuleEndpoint, serviceBusNamespace.apiVersion).primaryConnectionString

resource kvServiceBusConnString 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-ServiceBus'
  properties: {
    value: serviceBusConnString
  }
}

output serviceBusSecretUri string = kvServiceBusConnString.properties.secretUri
