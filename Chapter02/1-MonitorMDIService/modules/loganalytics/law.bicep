param location string
param logAnalyticsWorkspaceName string
param retentionInDays int
param sku string
param dailyQuotaGb int

// Deploy the Log Analytics workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: sku
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
  }
}

output workspaceResourceId string = workspace.id
output workspaceId string = workspace.properties.customerId
