@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

// TODO: Utwórz zasób Azure SignalR
resource signalR 'Microsoft.SignalRService/signalR@2022-02-01' = {
  // ...
}

resource kvSignalRConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-SignalR'
  properties: {
    value: listKeys(signalR.name, signalR.apiVersion).primaryConnectionString
  }
}

output signalrSecretUri string = kvSignalRConnString.properties.secretUri
