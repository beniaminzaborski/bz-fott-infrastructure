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

resource topicTimeCalculated 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competitor-time-calculated'
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
  name: 'registration-completed-events-to-registr-service'
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

resource queueTimeCalculatedEventsToRegistrationService 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'competitor-time-calculated-events-to-registr-service'
  properties: {
    enablePartitioning: false
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

// Subsciptions
resource subsCompetitionEventsToRegistrationServiceMaxCompetitorsIncreased 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  // ...
}

resource subsCompetitionEventsToRegistrationServiceOpenedForRegistration 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  // ...
}

resource subsCompetitionEventsToRegistrationServiceRegistrationCompleted 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  // ...
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
  name: 'registration-completed-events-to-registr-service'
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

resource subsTimeCalculatedEventsToRegistrationService 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: topicTimeCalculated
  name: 'time-calculated-events-to-registr-service'
  properties: {
    forwardTo: queueTimeCalculatedEventsToRegistrationService.name
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
