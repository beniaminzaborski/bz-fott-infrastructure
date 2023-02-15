@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    ImmediatePurgeDataOn30Days: true
    RetentionInDays: 30
  }
}

resource kvAppInsightsConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-AppInsights'
  properties: {
    value: applicationInsights.properties.ConnectionString
  }
}

output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output appInsightsSecretUri string = kvAppInsightsConnString.properties.secretUri
