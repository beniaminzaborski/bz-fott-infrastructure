@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

@secure()
param appInsightsSecretUri string

param appInsightsInstrumentationKey string

@secure()
param registrDbSecretUri string

@secure()
param serviceBusSecretUri string

@secure()
param signalrSecretUri string

@description('App plan SKU')
param appServicesSku object

resource registrAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${projectName}-registr-${environment}-${shortLocation}'
  location: location
  sku: {
    name: appServicesSku[environment].name
  }
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
  kind: 'linux'
}

resource registrSrvLessAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${projectName}-slregistr-${environment}-${shortLocation}'
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

resource registrAppService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${projectName}-registr-${environment}-${shortLocation}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'app'
  properties: {
    enabled: true
    serverFarmId: registrAppPlan.id
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      vnetRouteAllEnabled: true
      alwaysOn: appServicesSku[environment].name == 'F1' ? false : true
      linuxFxVersion: 'DOTNETCORE|7.0'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'ConnectionStrings__Postgres'
          value: '@Microsoft.KeyVault(SecretUri=${registrDbSecretUri})'
        }
        {
          name: 'ConnectionStrings__AzureServiceBus'
          value: '@Microsoft.KeyVault(SecretUri=${serviceBusSecretUri})'
        }
        {
          name: 'ConnectionStrings__ApplicationInsights'
          value: '@Microsoft.KeyVault(SecretUri=${appInsightsSecretUri})'
        }
      ]
    }
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

// Dedicated Strorage Account for Azure Function App
resource storageAccountRegistrFuncApp 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'st${projectName}fregistr${environment}${shortLocation}'
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

resource registrFuncApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'func-${projectName}-registr-${environment}-${shortLocation}'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: registrSrvLessAppPlan.id
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          //value: '@Microsoft.KeyVault(SecretUri=${storageAccountSecretUri})'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountRegistrFuncApp.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccountRegistrFuncApp.id, storageAccountRegistrFuncApp.apiVersion).keys[0].value}'
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
          name: 'PostgresConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${registrDbSecretUri})'
        }
        {
          name: 'SignalRConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${signalrSecretUri})'
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
        objectId: registrAppService.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: registrFuncApp.identity.principalId
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
