// Parameters
@description('The name of the data collection rule, needs to have the suffix "MSVMI-"')
param dcrName string

@description('The resource ID of the target Log Analytics workspace, e.g. /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sentinel/providers/Microsoft.OperationalInsights/workspaces/log-analytics-workspace')
param workspaceId string

@description('The resource ID of the data collection endpoint')
param dataCollectionEndpointId string

@description('Setting the location of the DCR as the same as the resource group')
param location string = resourceGroup().location

@description('The complete path to the file to be collected, e.g. C:\\Logs\\CustomLog.json or C:\\Logs\\CustomLog.txt')
param filePath string

@description('The name of the custom table (_CL) in the Log Analytics workspace, needs to be pre-created in Log Analytics')
param tableName string

param columns array

var streamName = 'Custom-Json-stream'
var tableOutputStream = 'Custom-${tableName}'

// Resource
resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  kind: 'Windows'
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
    streamDeclarations: {
      '${streamName}': {
        columns: [
          for column in columns: {
            name: column.name
            type: column.type
          }
        ]
      }
    }
    dataSources: {
      logFiles: [
        {
          streams: [
            streamName
          ]
          filePatterns: [
            filePath
          ]
          format: 'json'
          name: streamName
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceId
          name: 'law'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          streamName
        ]
        destinations: [
          'law'
        ]
        transformKql: 'source'
        outputStream: tableOutputStream
      }
    ]
  }
}

output id string = dcr.id
