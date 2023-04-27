@description('Azure region')
param location string = resourceGroup().location
var shortLocation = substring(location, 0, 6)

@description('Project name as a prefix for all resources')
@minLength(3)
param projectName string = 'fott'

@description('The administrator username of the SQL logical server')
param dbAdminLogin string = 'postgres'

@secure()
param dbAdminPassword string

@description('Environment name')
@minLength(2)
@allowed(['dev', 'qa', 'stg', 'prd'])
param environment string

var createdBy = 'Beniamin'

var appServicesSku = {
  dev: {
    name: 'F1'
  }
  qa: {
    name: 'B1'
  }
  stg: {
    name: 'P1V2'
  }
  prod: {
    name: 'P1V2'
  }
}

module vaults 'modules/vaults.bicep' = {
  name: 'vaultModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
}

module observability 'modules/observability.bicep' = {
  name: 'observabilityModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
  ]   
}

module databases 'modules/databases.bicep' = {
  name: 'databaseModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
    dbAdminLogin: dbAdminLogin
    dbAdminPassword: dbAdminPassword
  }
  dependsOn: [
    vaults
  ]  
}

module messaging 'modules/messaging.bicep' = {
  name: 'messagingModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
  ]  
}

module appAdmin 'modules/app-admin.bicep' = {
  name: 'appAdminModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
    appInsightsSecretUri: observability.outputs.appInsightsSecretUri
    adminDbSecretUri: databases.outputs.adminDbSecretUri
    serviceBusSecretUri: messaging.outputs.serviceBusSecretUri
    appServicesSku: appServicesSku
  }
  dependsOn: [
    vaults
    databases
    messaging
    observability
  ]  
}
