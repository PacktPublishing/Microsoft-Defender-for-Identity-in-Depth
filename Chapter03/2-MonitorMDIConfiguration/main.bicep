param location string = resourceGroup().location
param logAnalyticsWorkspaceName string
param dcrName string = 'MDIConfig-dcr'
param filePath string = 'C:\\temp\\MDIConfig\\MDI-configuration.json'
param customTableName string = 'MDIConfig_CL'
param retentionInDays int = 30

@description('The name of the data collection endpoint.')
param dataCollectionEndpointName string = 'dce-${location}'

var columns = [
  {
    name: 'TimeGenerated'
    type: 'datetime'
  }
  {
    name: 'RawData'
    type: 'string'
  }
  // Add more columns as needed
]

@description('The names of the virtual machines that will be associated with the Data Collection Rule.')
param vmNames array = [
  'CONTOSOCS'
]

// Get existing virtual machines from the array of names
resource vms 'Microsoft.Compute/virtualMachines@2024-03-01' existing = [for vmName in vmNames: {
  name: vmName
}]

// Get existing Log Analytics Workspace from the name
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

module customTableModule 'modules/loganalyticscustomtable/customTable.bicep' = {
  name: 'createMDICustomTable'
  params: {
    logAnalyticsWorkpaceName: logAnalyticsWorkspaceName
    tableName: customTableName
    retentionInDays: retentionInDays
    columns: columns
  }
}

output tableId string = customTableModule.outputs.tableId

module dataCollectionEndpoint 'modules/datacollection/dce.bicep' = {
  name: 'dataCollectionEndpoint'
  params: {
    dataCollectionEndpointName: dataCollectionEndpointName
  }
}

// Deploy a Data Collection Rule
module dataCollectionRule 'modules/datacollection/dcr.bicep' = {
  name: 'createMDIDataCollectionRule'
  params: {
    location: resourceGroup().location
    workspaceId: law.id
    dcrName: dcrName
    dataCollectionEndpointId: dataCollectionEndpoint.outputs.id
    filePath: filePath
    tableName: customTableName
    columns: columns
  }
}

resource association 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = [for (vmId, index) in vmNames : {
  name: 'dcr-association-${index}'
  properties: {
    description: 'Association of data collection rule. Deleting this association will break log ingestion described in the data collection rule.'
    dataCollectionRuleId: dataCollectionRule.outputs.id
  }
  scope: vms[index]
  dependsOn: [
    law
    dataCollectionRule
    vms
    dataCollectionEndpoint
  ]
}]
