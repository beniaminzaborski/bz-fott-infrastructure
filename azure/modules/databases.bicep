@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

@description('The administrator username of the SQL logical server')
param dbAdminLogin string

@secure()
param dbAdminPassword string

// TODO: Utwórz zasób PostgreSQL
resource postgres 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  // ...
}

// TODO: Dodaj regułę firewall dla PostgreSQL
resource postgresFirewallRules 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  // ...
}

// TODO: Utwórz bazę danych na serwerze PostgreSQL dla usługi Admin
resource adminDB 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  // ...
}

// TODO: Dodaj connection string do KeyVault Secrets
resource kvAdminDbPostgresConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  // ...
  // value: 'Server=${postgres.name}.postgres.database.azure.com;Database=${adminDB.name};Port=5432;Ssl Mode=Require;Trust Server Certificate=true;User Id=${dbAdminLogin}@${postgres.name};Password=${dbAdminPassword};'
}

// TODO: Zwróć connection string do bazy danych w PostgreSQL z KeyVault
output adminDbSecretUri string = // ...
