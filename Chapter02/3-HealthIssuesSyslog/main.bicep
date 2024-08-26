targetScope = 'subscription'

// Parameters

param location string

@description('When deploying the stack N times, define the instance - this will be appended to some resource names to avoid collisions.')
param deploymentNumber string = '1'

@description('Name of the virtual machines to be created')
param vmName string

@description('Name of the virtual network, where the load balancer and virtual machines will be created')
param virtualNetworkName string

@description('Name of the subnet in the virtual network where the load balancers will be created. If not specified, will use the same subnet as the virtual machines')
param lbSubnetName string

@description('Name of the subnet within the virtual network where the virtual machines will be connected to')
param vmSubnetName string

@description('The name of the Resource Group containing the Virtual Network')
param virtualNetworkResourceGroup string

@description('Name of the Resource Group where the existing Log Analyics workspace resides')
param workspaceResourceGroup string

@description('Name of the existing Log Analytics workspace with Sentinel')
param workspaceName string

@description('Name of Data Collection Rule to be created')
param dcrName string

@secure()
param adminPassword string = newGuid()

param environment string

@minValue(1)
@maxValue(4)
param SyslogSrvToDeploy int

param os string = 'Ubuntu'
param vmSize string = 'Standard_D2s_v5'
param storageAccountType string
param osDiskSize int
param dataDiskSize int
param adminUserName string
param deploymentNamePrefix string
param authenticationType string = 'password'

// Variables

var shortenedLocation = location == 'westeurope' ? 'weu' : location == 'swedencentral' ? 'sec' : location

@description('Format string of the resource names.')
var resourceNameFormat = '{0}-syslog-${environment}-${shortenedLocation}'

@description('Format string of storage account name.')
var resourceNameFormat_storageAccount = '{0}syslog${environment}${shortenedLocation}'


var osDetails = {
  Ubuntu: {
    imageReference: {
      publisher: 'canonical'
      offer: '0001-com-ubuntu-server-jammy'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    configScriptName: 'ubuntu_config.sh'
  }
}

var workspaceId = reference(logAnalytics.id, '2015-11-01-preview').customerId
var workspaceKey = listKeys(logAnalytics.id, '2015-11-01-preview').primarySharedKey

// Resources

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroup)
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: workspaceName
  scope: resourceGroup(workspaceResourceGroup)
}

resource target_resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: format(resourceNameFormat, 'rg', deploymentNumber)
  location: location
}

module storageAccount './modules/storageAccount.bicep' = {
  name: '${deploymentNamePrefix}sa'
  scope: target_resourceGroup
  params: {
    location: location
    resourceNameFormat: resourceNameFormat_storageAccount
    containerName: 'scripts'
    scriptUrl: 'https://raw.githubusercontent.com/pthoor/Microsoft-Defender-for-Identity-in-Depth/main/Chapter2/Bicep_Syslog/scripts/ubuntu_config.sh'
  }
}

// Find the scripts location from the storage account module output
var scriptsLocation = storageAccount.outputs.scriptFileUrl

module loadBalancerInternal './modules/internalloadbalancer.bicep' = if (SyslogSrvToDeploy >= 2) {
  name: '${deploymentNamePrefix}lbi'
  scope: target_resourceGroup
  params: {
    location: location
    subnetName: empty(lbSubnetName) ? vmSubnetName : lbSubnetName
    resourceNameFormat: resourceNameFormat
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
  }
}

module availabilitySet './modules/availabilitySet.bicep' = if (SyslogSrvToDeploy >= 2) {
  name: '${deploymentNamePrefix}avail'
  scope: target_resourceGroup
  params: {
    location: location
    resourceNameFormat: resourceNameFormat
  }
}

module vm './modules/vm.bicep' = [for i in range(0, SyslogSrvToDeploy): {
  name: '${deploymentNamePrefix}vm-${vmName}-${i}'
  scope: target_resourceGroup
  params: {
    vmName: 'vm-${vmName}-${i}'
    adminUserName: adminUserName
    osDetail: osDetails[os]
    nicName: 'nic-${vmName}-${i}'
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    subnetName: vmSubnetName
    osDiskName: 'osDisk-${vmName}-${i}'
    osDiskSize: osDiskSize
    dataDiskName: 'dataDisk-${vmName}-${i}'
    dataDiskSize: dataDiskSize
    storageAccountType: storageAccountType
    adminPasswordOrKey: adminPassword
    location: location
    vmSize: vmSize
    workspaceId: workspaceId
    workspaceKey: workspaceKey
    scriptsLocation: scriptsLocation
    lbiBackendAddressPoolId: SyslogSrvToDeploy >= 2 ? loadBalancerInternal.outputs.backendAddressPoolId : ''
    avsetId: availabilitySet.outputs.avsetId
    authenticationType: authenticationType
  }
  dependsOn: [
    storageAccount
  ]
}]

module dcr 'modules/dataCollectionRule.bicep' = {
  name: '${deploymentNamePrefix}dcr'
  scope: target_resourceGroup
  params: {
    dcrName: dcrName
    logAnalyticsWorkspaceId: logAnalytics.id
  }
}
