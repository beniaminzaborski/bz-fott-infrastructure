@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

/* Service Bus */
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

// Topics/Queues/Subscriptions
resource topicCompletedRegistrations 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'completed-registrations'
  properties: {
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

resource queueCompletedRegistrationsTelemetry 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'completed-registrations-telemetry'
  properties: {

  }
}

resource subsCompletedRegistrations 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicCompletedRegistrations
  name: 'completed-registrations-telemetry'
  properties: {
    forwardTo: queueCompletedRegistrationsTelemetry.name
    requiresSession: false
  }
}

var serviceBusNamespaceAuthRuleEndpoint = '${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnString = listKeys(serviceBusNamespaceAuthRuleEndpoint, serviceBusNamespace.apiVersion).primaryConnectionString

resource kvServiceBusConnString 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-ServiceBus'
  properties: {
    value: serviceBusConnString
  }
}

output serviceBusSecretUri string = kvServiceBusConnString.properties.secretUri


/* Event Hubs */
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: 'evhns-${projectName}-${environment}-${shortLocation}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  parent: eventHubNamespace
  name: 'evh-${projectName}-${environment}-${shortLocation}'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 1
  }
}

var eventHubNamespaceAuthRuleEndpoint = '${eventHubNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'
var eventHubConnString = listKeys(eventHubNamespaceAuthRuleEndpoint, eventHubNamespace.apiVersion).primaryConnectionString

resource kvEventHubConnString 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-EventHub'
  properties: {
    value: eventHubConnString
  }
}

output eventHubSecretUri string = kvServiceBusConnString.properties.secretUri
