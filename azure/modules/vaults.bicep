@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

// TODO: Utwórz zasób KeyVault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  // ...
}
