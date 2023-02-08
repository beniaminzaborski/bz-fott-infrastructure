@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

param appInsightsInstumentationKey string

@secure()
param adminDbSecretUri string

@secure()
param serviceBusSecretUri string

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
          name: 'ApplicationInsights__InstrumentationKey'
          value: appInsightsInstumentationKey
        }
        {
          name: 'ConnectionStrings__Administration'
          value: '@Microsoft.KeyVault(SecretUri=${adminDbSecretUri})'
        }
        {
          name: 'AzureServiceBus__ConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${serviceBusSecretUri})'
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
    ]
  }
}
