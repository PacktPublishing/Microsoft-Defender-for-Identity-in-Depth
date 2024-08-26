param tableName string
param retentionInDays int
param columns array

param logAnalyticsWorkpaceName string

resource customTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  name: '${logAnalyticsWorkpaceName}/${tableName}'
  properties: {
    retentionInDays: retentionInDays
    schema: {
      name: tableName
      columns: [
        for column in columns: {
          name: column.name
          type: column.type
        }
      ]
    }
  }
}

output tableId string = customTable.id
