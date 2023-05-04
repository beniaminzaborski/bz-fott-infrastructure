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

// TODO: Utwórz zasób App Servie Plan typu serverless
resource telemtrSrvLessAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  // ...
}

// TODO: Utwórz zasób Storage Account dla Azure Function App
resource storageAccountTelemtrFuncApp 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  // ...
}

// TODO: Utwórz zasób Azure Function App
resource telemtrFuncApp 'Microsoft.Web/sites@2022-03-01' = {
  // ...
}

// TODO: Nadaj uprawnienia do Secrets w KeyVaults dla Azure Function App
resource vaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  // ...
}
