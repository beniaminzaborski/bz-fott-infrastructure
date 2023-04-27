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

output adminDbSecretUri string = kvAdminDbPostgresConnString.properties.secretUri
