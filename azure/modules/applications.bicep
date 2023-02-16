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
param adminDbSecretUri string

@secure()
param registrDbSecretUri string

@secure()
param serviceBusSecretUri string

// @secure()
// param storageAccountSecretUri string

@secure()
param signalrSecretUri string

@description('App plan SKU')
param appServicesSku object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${projectName}-${environment}-${shortLocation}'
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

resource appfunctionPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${projectName}-slregistration-${environment}-${shortLocation}'
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

resource adminAppService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${projectName}-administration-${environment}-${shortLocation}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'app'
  properties: {
    enabled: true
    serverFarmId: appServicePlan.id
    siteConfig: {
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
          value: '@Microsoft.KeyVault(SecretUri=${adminDbSecretUri})'
        }
        {
          name: 'ConnectionStrings__AzureServiceBus'
          value: '@Microsoft.KeyVault(SecretUri=${serviceBusSecretUri})'
        }
        {
          name: 'ConnectionStrings__ApplicationInsights'
          value: appInsightsInstrumentationKey
        }
      ]
    }
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

resource registrAppService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${projectName}-registration-${environment}-${shortLocation}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'app'
  properties: {
    enabled: true
    serverFarmId: appServicePlan.id
    siteConfig: {
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
          value: appInsightsInstrumentationKey
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
  name: 'func-${projectName}-registration-${environment}-${shortLocation}'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appfunctionPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          //value: '@Microsoft.KeyVault(SecretUri=${appInsightsSecretUri})'
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
        objectId: adminAppService.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }
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
