@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

param appInsightsInstrumentationKey string

@secure()
param telemtrDbSecretUri string

@secure()
param eventHubSecretUri string

@secure()
param serviceBusSecretUri string

@secure()
param signalrSecretUri string


resource telemtrSrvLessAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${projectName}-sltelemtr-${environment}-${shortLocation}'
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    //reserved: true // on Linux
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

// Dedicated Strorage Account for Azure Function App
resource storageAccountTelemtrFuncApp 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'st${projectName}ftelemtr${environment}${shortLocation}'
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

resource telemtrFuncApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'func-${projectName}-telemtr-${environment}-${shortLocation}'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: telemtrSrvLessAppPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          //value: '@Microsoft.KeyVault(SecretUri=${storageAccountSecretUri})'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountTelemtrFuncApp.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccountTelemtrFuncApp.id, storageAccountTelemtrFuncApp.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'ServiceBusConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${serviceBusSecretUri})'
        }
        {
          name: 'CosmosConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${telemtrDbSecretUri})'
        }
        {
          name: 'EventHubConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${eventHubSecretUri})'
        }
      ]
    }
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

resource vaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/add'
  properties: {
    accessPolicies: [
      {
        objectId: telemtrFuncApp.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }           
    ]
  }
}
