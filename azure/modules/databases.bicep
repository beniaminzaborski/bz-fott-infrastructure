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

/* PostgreSQL */
resource postgres 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'psql-${projectName}-${environment}-${shortLocation}'
  location: location
  sku: {
    name: 'B_Gen5_1'
    tier: 'Basic'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    administratorLogin: dbAdminLogin
    administratorLoginPassword: dbAdminPassword
    createMode: 'Default'
    version: '11'
    sslEnforcement: 'Enabled'
    publicNetworkAccess: 'Enabled'
  }
}

resource postgresFirewallRules 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: postgres
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource adminDB 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: 'fott_administration'
  parent: postgres
}

resource kvAdminDbPostgresConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-Administration-Postgres'
  properties: {
    value: 'Server=${postgres.name}.postgres.database.azure.com;Database=${adminDB.name};Port=5432;Ssl Mode=Require;Trust Server Certificate=true;User Id=${dbAdminLogin}@${postgres.name};Password=${dbAdminPassword};'
  }
}

resource registrDB 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: 'fott_registration'
  parent: postgres
}

resource kvRegistrDbPostgresConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-Registration-Postgres'
  properties: {
    value: 'Server=${postgres.name}.postgres.database.azure.com;Database=${registrDB.name};Port=5432;Ssl Mode=Require;Trust Server Certificate=true;User Id=${dbAdminLogin}@${postgres.name};Password=${dbAdminPassword};'
  }
}

output adminDbSecretUri string = kvAdminDbPostgresConnString.properties.secretUri
output registrDbSecretUri string = kvRegistrDbPostgresConnString.properties.secretUri


/* CosmosDB */
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
  {
    locationName: 'northeurope' //secondaryRegion
    failoverPriority: 1
    isZoneRedundant: false
  }
]

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: 'cosacc-${projectName}-${environment}-${shortLocation}'
  kind: 'MongoDB'
  location: location
  properties: {
    //consistencyPolicy: consistencyPolicy['Eventual']
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2022-08-15' = {
  name: 'fott_telemetry'
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: 'fott_telemetry'
    }
  }
}

resource kvTelemtrDbComosConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-Telemetry-Cosmos'
  properties: {
    value: cosmosDbAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output telemtrDbSecretUri string = kvTelemtrDbComosConnString.properties.secretUri
