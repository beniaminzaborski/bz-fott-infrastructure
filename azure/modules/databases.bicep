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

param secondaryRegion string

var competitorsContainerName = 'Competitors'
var checkpointsContainerName = 'Checkpoints'
var laptimeContainerName = 'LapTimes'

var sqlDatabaseNames = [
  'Fott-Administration'
  'Fott-Registration'
]

/* PostgreSQL */
resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: 'psql-${projectName}-${environment}-${shortLocation}'
  location: location
  sku: {
    name: 'Standard_D4ds_v4'
    tier: 'GeneralPurpose'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    administratorLogin: dbAdminLogin
    administratorLoginPassword: dbAdminPassword
    createMode: 'Default'
    version: '14'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }
}

resource postgresFirewallRules 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: postgres
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// Create Postgres databases in the loop one by one
resource psqlDB 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = [for sqlDbName in sqlDatabaseNames: {
  name: sqlDbName
  parent: postgres
}]

// Put Postgres database connection strings into Key Vault in the loop one by one
resource psqlDBConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for sqlDbName in sqlDatabaseNames: {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-${sqlDbName}-Postgres'
  properties: {
    value: 'Server=${postgres.name}.postgres.database.azure.com;Database=${sqlDbName};Port=5432;Ssl Mode=Require;Trust Server Certificate=true;User Id=${dbAdminLogin}@${postgres.name};Password=${dbAdminPassword};'
  }
}]

output adminDbSecretUri string = psqlDBConnString[0].properties.secretUri
output registrDbSecretUri string = psqlDBConnString[1].properties.secretUri

/* CosmosDB */
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
  {
    locationName: secondaryRegion
    failoverPriority: 1
    isZoneRedundant: false
  }
]

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: 'cosacc-${projectName}-${environment}-${shortLocation}'
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    locations: locations
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-08-15' = {
  name: 'fott_telemetry'
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: 'fott_telemetry'
    }
    options: {
      throughput: 1000
    }
  }
}

resource  competitorsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  parent: cosmosDb
  name: competitorsContainerName
  properties: {
    resource: {
      id: competitorsContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
              path: '/\'_etag\'/?'
          }
        ]
      }
    }
  }
}

resource checkpointsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  parent: cosmosDb
  name: checkpointsContainerName
  properties: {
    resource: {
      id: checkpointsContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
              path: '/\'_etag\'/?'
          }
        ]
      }
    }
  }
}

resource laptimeContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  parent: cosmosDb
  name: laptimeContainerName
  properties: {
    resource: {
      id: laptimeContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
              path: '/\'_etag\'/?'
          }
        ]
      }
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
