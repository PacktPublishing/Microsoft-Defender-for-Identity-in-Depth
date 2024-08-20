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

// Install the Microsoft Sentinel solution on the Log Analytics workspace
resource solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspace.name})'
  location: location
  properties: {
    workspaceResourceId: workspace.id
  }
  plan: {
    name: 'SecurityInsights(${workspace.name})'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

output workspaceResourceId string = workspace.id
