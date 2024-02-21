@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource signalR 'Microsoft.SignalRService/signalR@2022-02-01' = {
  name: 'sigr-${projectName}-${environment}-${shortLocation}'
  location: location
  sku: {
    name: 'Free_F1'
    tier: 'Free'
  }
  kind: 'SignalR'
  properties: {
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
    publicNetworkAccess: 'Enabled'
    features: [
      {
        flag: 'ServiceMode'
        value: 'Serverless'
      }
    ]
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

resource kvSignalRConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-SignalR'
  properties: {
    value: signalR.listKeys().primaryConnectionString
  }
}

output signalrSecretUri string = kvSignalRConnString.properties.secretUri
