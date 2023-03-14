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

// Topics
resource topicCheckpointAdded 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competition-checkpoint-added'
  properties: {
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

resource topicCheckpointRemoved 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competition-checkpoint-removed'
  properties: {
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

resource topicMaxCompetitorsIncreased 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competition-max-competitors-increased'
  properties: {
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

resource topicCompetitionOpenedForRegistration 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competition-opened-for-registration'
  properties: {
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

resource topicCompetitionRegistrationCompleted 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competition-registration-completed'
  properties: {
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

resource topicRegistrationCompleted 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'registration-completed'
  properties: {
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

// Queues
resource queueCompetitionEventsToRegistrationService 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competition-events-to-registration-service'
  properties: {
    enablePartitioning: false
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

resource queueRegistrationCompletedEventsToTelemetry 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'registration-completed-events-to-telemetry-service'
  properties: {
    enablePartitioning: false
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

resource queueRegistrationCompletedEventsToRegistration 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'registration-completed-events-to-registration-service'
  properties: {
    enablePartitioning: false
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

resource queueAddCheckpointEventsToTelemetryService 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'add-checkpoint-events-to-telemetry-service'
  properties: {
    enablePartitioning: false
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

resource queueRemoveCheckpointEventsToTelemetryService 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'remove-checkpoint-events-to-telemetry-service'
  properties: {
    enablePartitioning: false
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

// Subsciptions
resource subsCompetitionEventsToRegistrationServiceMaxCompetitorsIncreased 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicMaxCompetitorsIncreased
  name: 'competition-events-to-registration-service'
  properties: {
    forwardTo: queueCompetitionEventsToRegistrationService.name
    requiresSession: false
  }
}

resource subsCompetitionEventsToRegistrationServiceOpenedForRegistration 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicCompetitionOpenedForRegistration
  name: 'competition-events-to-registration-service'
  properties: {
    forwardTo: queueCompetitionEventsToRegistrationService.name
    requiresSession: false
  }
}

resource subsCompetitionEventsToRegistrationServiceRegistrationCompleted 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicCompetitionRegistrationCompleted
  name: 'competition-events-to-registration-service'
  properties: {
    forwardTo: queueCompetitionEventsToRegistrationService.name
    requiresSession: false
  }
}

resource subsRegistrationCompletedEventsToTelemetry 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicRegistrationCompleted
  name: 'registration-completed-events-to-telemetry-service'
  properties: {
    forwardTo: queueRegistrationCompletedEventsToTelemetry.name
    requiresSession: false
  }
}

resource subsRegistrationCompletedEventsToRegistration 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicRegistrationCompleted
  name: 'registration-completed-events-to-registration-service'
  properties: {
    forwardTo: queueRegistrationCompletedEventsToRegistration.name
    requiresSession: false
  }
}

resource subsAddCheckpointEventsToTelemetryService 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicCheckpointAdded
  name: 'add-checkpoint-events-to-telemetry-service'
  properties: {
    forwardTo: queueAddCheckpointEventsToTelemetryService.name
    requiresSession: false
  }
}

resource subsRemoveCheckpointEventsToTelemetryService 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicCheckpointRemoved
  name: 'remove-checkpoint-events-to-telemetry-service'
  properties: {
    forwardTo: queueRemoveCheckpointEventsToTelemetryService.name
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
