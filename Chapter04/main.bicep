extension microsoftGraph

@description('The name of the application to create.')
param appName string = 'GraphAPI-MDI-Test'

@description('The name of the secret to create.')
param secretName string = 'GraphAPI-MDI-Test-Secret'

@description('The end date and time for the secret.')
param EndDateTime string = '2029-12-31T23:59:59Z'

resource app 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: appName
  displayName: appName
  signInAudience: 'AzureADMyOrg'
  passwordCredentials: [
    {
      displayName: secretName
      endDateTime: EndDateTime
    }
  ]
  requiredResourceAccess: [
    {
      resourceAppId: '00000003-0000-0000-c000-000000000000' // Microsoft Graph
      resourceAccess: [
        {
          id: 'f8dcd971-5d83-4e1e-aa95-ef44611ad351' // SecurityIdentitiesHealth.Read.All
          type: 'Role'
        }
        {
          id: '45cc0394-e837-488b-a098-1918f48d186c' // SecurityIncident.Read.All
          type: 'Role'
        }
        {
          id: 'bf394140-e372-4bf9-a898-299cfc7564e5' // SecurityEvents.Read.All
          type: 'Role'
        }
        {
          id: '472e4a4d-bb4a-4026-98d1-0b0d74cb74a5' // SecurityAlert.Read.All
          type: 'Role'
        }
      ]
    }
  ]
}

resource sp 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: app.appId
}

output appId string = app.appId
output spId string = sp.id
output secretValue string = app.passwordCredentials[0].secretText
