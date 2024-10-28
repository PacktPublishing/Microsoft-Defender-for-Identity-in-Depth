@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

@description('Key Vault SKU')
param sku string
param skuCode string

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'get'
  'list'
]

//param guidValue string = newGuid()
var kvName = 'kv${uniqueString(resourceGroup().id)}'

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: kvName
  location: location
  properties: {
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    enableRbacAuthorization: false
    enablePurgeProtection: true
    sku: {
      family: skuCode
      name: sku
    }
    accessPolicies: [
      {
        objectId: objectId
        permissions: {
          secrets: secretsPermissions
        }
        tenantId: tenantId
      }
    ]
    softDeleteRetentionInDays: 7
    tenantId: tenantId
  }
}

output kvUri string = keyVault.properties.vaultUri
output kvName string = keyVault.name
output location string = location
output resourceGroupName string = resourceGroup().name
output kvresourceId string = keyVault.id
