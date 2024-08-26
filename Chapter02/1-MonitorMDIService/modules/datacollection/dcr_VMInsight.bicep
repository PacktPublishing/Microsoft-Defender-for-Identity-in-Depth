@description('The name of the data collection rule needs to have the suffix "MSVMI-"')
param dcr_name string = 'MSVMI-ama-vmi-default-dcr'

@description('The resource ID of the target Log Analytics workspace e.g. /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sentinel/providers/Microsoft.OperationalInsights/workspaces/log-analytics-workspace')
param workspaceId string

@description('Setting the location of the DCR as the same as the resource group')
param location string = resourceGroup().location

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcr_name
  location: location
  properties: {
    description: 'Data collection rule for VM Insights.'
    dataSources: {
      performanceCounters: [
        {
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
          name: 'VMInsightsPerfCounters'
        }
      ]
      extensions: [
        {
          streams: [
            'Microsoft-ServiceMap'
          ]
          extensionName: 'DependencyAgent'
          extensionSettings: {}
          name: 'DependencyAgentDataSource'
        }
      ]
    }    
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceId
          name: 'VMInsightsPerf-Logs-Dest'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
      {
        streams: [
          'Microsoft-ServiceMap'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
}

output id string = dataCollectionRule.id
