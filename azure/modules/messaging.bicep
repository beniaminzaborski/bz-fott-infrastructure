@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

// TODO: Utwórz zasób Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  // ...
}

var serviceBusNamespaceAuthRuleEndpoint = '${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnString = listKeys(serviceBusNamespaceAuthRuleEndpoint, serviceBusNamespace.apiVersion).primaryConnectionString

// TODO: Dodaj connection string do Message Bus do KeyVault Secrets
resource kvServiceBusConnString 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  // ...
}

// TODO: Zwróć connection do Message Bus z KeyVault
output serviceBusSecretUri string = // ...
