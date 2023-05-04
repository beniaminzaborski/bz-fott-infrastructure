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

// TODO: Utwórz App Service Plan typu serverless dla Azure Function App
resource registrSrvLessAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${projectName}-slregistr-${environment}-${shortLocation}'
  // ...
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

// TODO: Utwórz dedykowany Storage Account dla Azure Function App 
resource storageAccountRegistrFuncApp 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  // ...
}

// TODO: Utwórz zasób Azure Function App
resource registrFuncApp 'Microsoft.Web/sites@2022-03-01' = {
  // ...
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
