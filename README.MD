# Feet On The Tarmac - Infrastructure
![Project logo](./docs/fott-logo.png)

## Table of contents
* [General info](#general-info)
* [Technologies](#technologies)
* [Setup](#setup)

## General info
This is infrastructure in Azure cloud for "Feet On The Tarmac" project. It creates Azure services in PaaS model.
	
## Technologies
Project is created with:
* Bicep
	
## Setup
To run this project from GitHub actions:
* Create dedicated service principal in Azure, grab the result of it and put this as value of AZURE_CREDENTIALS secret in GitHub

```
az ad sp create-for-rbac --name "fott-github-actions-sp" --sdk-auth --role contributor --scopes /subscriptions/{subscriptions-id}
```

* Set the values of rest secrets/variables in GitHub such as: AZURE_RG (name of the resoure group in Azure where infrastucture will be deployed), AZURE_SUBSCRIPTION (id of Azure subscription), DB_ADMIN_LOGIN (login for database), DB_ADMIN_PASSWORD (password for database)

* Run GitHub workflow and pass the name of environment (dev, qa, stg, prod)
