@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location
param automationaccountname string

resource AutomationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: automationaccountname
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: true
    sku: {
      family: 'string'
      name: 'Basic'
    }
  }
}

resource ActiveDirectoryDsc 'Microsoft.Automation/automationAccounts/modules@2022-08-08' = {
  name: '${automationaccountname}/ActiveDirectoryDsc'
  dependsOn: [
    AutomationAccount
  ]
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ActiveDirectoryDsc/6.2.0'
      version: '6.2.0'
    }
  }
}

resource ComputerManagementDsc 'Microsoft.Automation/automationAccounts/modules@2022-08-08' = {
  name: '${automationaccountname}/ComputerManagementDsc'
  dependsOn: [
    AutomationAccount
  ]
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ComputerManagementDsc/8.5.0'
      version: '8.5.0'
    }
  }
}

resource NetworkingDsc 'Microsoft.Automation/automationAccounts/modules@2022-08-08' = {
  name: '${automationaccountname}/NetworkingDsc'
  dependsOn: [
    AutomationAccount
  ]
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/NetworkingDsc/9.0.0'
      version: '9.0.0'
    }
  }
}
