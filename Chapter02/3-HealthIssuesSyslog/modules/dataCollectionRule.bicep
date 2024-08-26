targetScope = 'resourceGroup'

param dcrName string
param logAnalyticsWorkspaceId string
param streamName string = 'Microsoft-Syslog'

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: resourceGroup().location
  kind: 'Linux'
  properties: {
    dataFlows: [
      {
        streams: [
          streamName
        ]
        destinations: [
          'logAnalytics'
        ]
      }
    ]
    dataSources: {      
      syslog: [
        {
          facilityNames: [
            'alert'
            'audit'
            'auth'
            'authpriv'
            'cron'
            'daemon'
            'ftp'
            'kern'
            'local0'
            'local1'
            'local2'
            'local3'
            'local4'
            'local5'
            'local6'
            'local7'
            'lpr'
            'mail'
            'mark'
            'news'
            'nopri'
            'ntp'
            'syslog'
            'user'
            'uucp'
          ]
          name: 'syslog'
          streams: [
            streamName
          ]
          logLevels: [
            'Info'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'logAnalytics'
          workspaceResourceId: logAnalyticsWorkspaceId
        }
      ]
    }
  }
}
