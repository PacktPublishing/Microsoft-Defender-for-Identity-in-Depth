param workspaceName string
param location string = resourceGroup().location
param workspaceResourceId string

resource changeTrackingSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ChangeTracking(${workspaceName})'
  location: location
  properties: {
    workspaceResourceId: workspaceResourceId
  }
  plan: {
    name: 'ChangeTracking(${workspaceName})'
    product: 'OMSGallery/ChangeTracking'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}
