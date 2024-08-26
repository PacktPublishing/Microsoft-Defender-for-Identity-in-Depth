targetScope = 'resourceGroup'

param location string = resourceGroup().location

@description('Name of the Log Analytics Workspace.')
param workspaceName string = 'law-monitoring'

@description('Log Analytics Workspace retention in days.')
param retentionInDays int = 30

@description('The name of the data collection rule for VM Insight, needs to have the suffix "MSVMI-"')
param dcr_name_vminsight string = 'MSVMI-ama-vmi-default-dcr'

@description('The name for the data collection rule for Change Tracking and Inventory')
param dcr_name_ct string = 'Microsoft-CT-DCR'

@description('The path to the file to be collected, e.g. C:\\Logs\\CustomLog.json')
param filePath string = 'C:\\temp\\MDIConfig\\MDI-configuration-report-CONTOSO.LOCAL.json'

@description('The names of the virtual machines that will be associated with the Data Collection Rule.')
param vmNames array = [
  'CONTOSODC0'
  'CONTOSOCS'
]

// Get existing virtual machines from the array of names
resource vms 'Microsoft.Compute/virtualMachines@2024-03-01' existing = [for vmName in vmNames: {
  name: vmName
}]

// Deploy Azure Monitor Agent on Azure Windows VM with System Assigned Managed Identity
module azureMonitorAgent 'modules/azuremonitoragent/amaWindows.bicep' = [for vmName in vmNames: {
  name: vmName
  params: {
    vmName: vmName
    location: location
  }
  dependsOn: [
    vms
  ]
}]

// Deploy a Log Analytics Workspace
module logAnalyticsWorkspace 'modules/loganalytics/law.bicep' = {
  name: workspaceName
  params: {
    location: location
    logAnalyticsWorkspaceName: workspaceName
    retentionInDays: retentionInDays
    sku: 'PerGB2018'
    dailyQuotaGb: 1
  }
}

// Deploy Change Tracking and Inventory Solution
module changeTrackingSolution 'modules/azuremonitoragent/ctSolutionWindows.bicep' = {
  name: 'ChangeTracking(${workspaceName})'
  params: {
    workspaceName: workspaceName
    location: location
    workspaceResourceId: logAnalyticsWorkspace.outputs.workspaceResourceId
  }
  dependsOn: [
    logAnalyticsWorkspace
    azureMonitorAgent
  ]
}

// Deploy a Data Collection Rule for VM Insights
module dataCollectionRuleVMInsight 'modules/datacollection/dcr_VMInsight.bicep' = {
  name: dcr_name_vminsight
  params: {
    location: location
    dcr_name: dcr_name_vminsight
    workspaceId: logAnalyticsWorkspace.outputs.workspaceResourceId
  }
  dependsOn: [
    logAnalyticsWorkspace
    azureMonitorAgent
  ]
}

// Associate the data collection rule (VM Insight) with the virtual machines
resource associationVMInsight 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = [for (vmId, index) in vmNames : {
  name: 'dcr-association-${index}'
  properties: {
    description: 'Association of data collection rule. Deleting this association will break log ingestion described in the data collection rule.'
    dataCollectionRuleId: dataCollectionRuleVMInsight.outputs.id
  }
  scope: vms[index]
  dependsOn: [
    dataCollectionRuleVMInsight
    azureMonitorAgent
    logAnalyticsWorkspace
    vms
  ]
}]

// Deploy DCR for Change Tracking and Inventory Solution
module dataCollectionRuleChangeTracking 'modules/datacollection/dcr_ChangeTracking.bicep' = {
  name: dcr_name_ct
  params: {
    location: location
    dcr_name: dcr_name_ct
    filePath: filePath
    workspaceId: logAnalyticsWorkspace.outputs.workspaceId
    workspaceResourceId: logAnalyticsWorkspace.outputs.workspaceResourceId
  }
  dependsOn: [
    logAnalyticsWorkspace
    azureMonitorAgent
    changeTrackingSolution
  ]
}

// Deploy Change Tracking Extension on Windows VM
module changeTrackingExtension 'modules/azuremonitoragent/changetrackingWindows.bicep' = [for vmName in vmNames: {
  name: '${vmName}-windows.ChangeTracking-Windows'
  params: {
    vmName: vmName
    location: location
  }
  dependsOn: [
    vms
    dataCollectionRuleChangeTracking
    azureMonitorAgent
    changeTrackingSolution
  ]
}]

// Associate the data collection rule (Change Tracking) with the virtual machines
resource associationChangeTracking 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = [for (vmId, index) in vmNames : {
  name: 'dcr-ct-association-${index}'
  properties: {
    description: 'Association of data collection rule. Deleting this association will break log ingestion described in the data collection rule.'
    dataCollectionRuleId: dataCollectionRuleChangeTracking.outputs.id
  }
  scope: vms[index]
  dependsOn: [
    dataCollectionRuleChangeTracking
    azureMonitorAgent
    logAnalyticsWorkspace
    vms
  ]
}]
