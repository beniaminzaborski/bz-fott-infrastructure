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

// TODO: Utwórz zadób App Service Plan
resource adminAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  // ...
}

// TODO: Utwórz zasób App Service
resource adminAppService 'Microsoft.Web/sites@2022-03-01' = {
  // ...
  kind: 'app'
  properties: {
    // ...
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
          value: // ...
        }
        {
          name: 'ConnectionStrings__ApplicationInsights'
          value: // ...
        }
      ]
    }
  }
  // ...
}

resource vaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/add'
  properties: {
    accessPolicies: [
      {
        objectId: adminAppService.identity.principalId
        permissions: {
          // ...
        }
        tenantId: subscription().tenantId
      }          
    ]
  }
}
