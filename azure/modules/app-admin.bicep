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

@secure()
param adminDbSecretUri string

@secure()
param serviceBusSecretUri string

@description('App plan SKU')
param appServicesSku object

resource adminAppPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'plan-${projectName}-admin-${environment}-${shortLocation}'
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

resource adminAppService 'Microsoft.Web/sites@2023-01-01' = {
  name: 'app-${projectName}-admin-${environment}-${shortLocation}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'app'
  properties: {
    enabled: true
    serverFarmId: adminAppPlan.id
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
          value: '@Microsoft.KeyVault(SecretUri=${adminDbSecretUri})'
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

resource vaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
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
    ]
  }
}
