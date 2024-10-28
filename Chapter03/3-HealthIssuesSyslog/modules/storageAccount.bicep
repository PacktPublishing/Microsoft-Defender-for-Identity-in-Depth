@description('Format string of the resource names.')
param resourceNameFormat string = '{0}syslog${uniqueString(resourceGroup().id, deployment().name)}'

param location string = resourceGroup().location
param containerName string
param scriptUrl string

param storageContributorRoleDefinitionId string = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: format(resourceNameFormat, 'sa')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

resource deploymentScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'deploymentScriptIdentity'
  location: location
}

resource dsRBAC 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, deploymentScriptIdentity.name, 'dsRBAC')
  scope: resourceGroup()
  properties: {
    principalId: deploymentScriptIdentity.properties.principalId
    roleDefinitionId: storageContributorRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'uploadGitHubFileToStorage'
  kind: 'AzurePowerShell'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${deploymentScriptIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '12.0'
    arguments: '-storageAccountName ${storageAccount.name} -resourceGroupName ${resourceGroup().name} -containerName ${containerName} -fileUrl ${scriptUrl}'
    scriptContent: '''
    param (
      [string] $storageAccountName,
      [string] $resourceGroupName,
      [string] $containerName,
      [string] $fileUrl
    )

    Connect-AzAccount -Identity

    $localFilePath = ${env:AZ_SCRIPTS_PATH_OUTPUT_DIRECTORY}

    # Download the file from GitHub
    Invoke-WebRequest -Uri $fileUrl -OutFile "ubuntu_config.sh"

    Write-Host "`n Creating blob in $containerName container"

    # Upload the file to Azure Storage
    $stg = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName
    $context = $stg.Context
    $scriptFileUrl = Set-AzStorageBlobContent -File '.\ubuntu_config.sh' -Container $containerName -Context $context -Force

    Write-Host $scriptFileUrl.ICloudBlob.Uri.AbsoluteUri

    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['scriptFileUrl'] = $scriptFileUrl.ICloudBlob.Uri.AbsoluteUri
    '''
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
  }
  dependsOn: [
    storageContainer
    dsRBAC
  ]
}

output scriptFileUrl string = deploymentScript.properties.outputs.scriptFileUrl
