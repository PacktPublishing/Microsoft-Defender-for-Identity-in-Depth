@description('This is the location in which all the linked templates are stored.')
param assetLocation string = 'https://raw.githubusercontent.com/pthoor/microsoft-defender-for-identity-in-depth/main/Chapter01/LabDeployment/'

// Key Vault parameters
@description('Globally unique Vault name must only contain alphanumeric characters and dashes and cannot start with a number.')
param sku string = 'standard'
param skuCode string = 'A'

@description('The object ID of the user or service principal that will be granted access to the Key Vault.')
param objectId string

@description('The overall environment name for the deployment.')
param environmentName string = 'contoso'

@description('Duration to retain Log Analytics workspace data, in days. Note that the pay-as-you-go pricing tier has a minimum 30-day retention.')
@minValue(30)
@maxValue(730)
param logAnalyticsWorkspaceRetention int = 30

@description('Daily quota for Log Analytics workspace data ingestion, in GB.')
@minValue(1)
@maxValue(10)
param logAnalyticsWorkspaceDailyQuota int = 5

var kvName = 'kv${uniqueString(resourceGroup().id)}'

// Deploy Key Vault
module keyvault 'modules/keyvault.bicep' = {
  name: kvName
  params: {
    objectId: objectId
    location: location
    sku: sku
    skuCode: skuCode
  }
}

@description('Username to set for the local User. Cannot be "Administrator", "root" and possibly other such common account names. ')
param adminUsername string = 'localAdmin'

@description('Password for the local administrator account. Cannot be "P@ssw0rd" and possibly other such common passwords. Must be 8 characters long and three of the following complexity requirements: uppercase, lowercase, number, special character')
@secure()
param adminPassword string = 'rP_LZmhEzhQ3KF3'
//param adminPassword string = newGuid()

@description('Two-part internal AD name - short/NB name will be first part (\'contoso\').')
param adDomainName string = 'contoso.local'

//@description('JSON object array of users that will be loaded into AD once the domain is established.')
//param usersArray array = [
//  {
//    FName: 'Bob'
//    LName: 'Jones'
//    SAM: 'bjones'
//  }
//  {
//    FName: 'Bill'
//    LName: 'Smith'
//    SAM: 'bsmith'
//  }
//  {
//    FName: 'Mary'
//    LName: 'Phillips'
//    SAM: 'mphillips'
//  }
//  {
//    FName: 'Sue'
//    LName: 'Jackson'
//    SAM: 'sjackson'
//  }
//]

//@description('Enter the password that will be applied to each user account to be created in AD.')
//@secure()
//param defaultUserPassword string = 'rP_LZmhEzhQ3KF3'
//param defaultUserPassword string = newGuid() rP_LZmhEzhQ3KF3

@description('An ADFS/WAP server combo will be setup independently this number of times. NOTE: it\'s unlikely to ever need more than one - additional farm counts are for edge case testing.')
@allowed([
  '1'
  '2'
])
param AdfsFarmCount string = '1'

@description('Select a VM SKU (please ensure the SKU is available in your selected region).')
@allowed([
  'Standard_A1_v2'
  'Standard_A2_v2'
  'Standard_A4_v2'
  'Standard_A2M_v2'
  'Standard_A4M_v2'
  'Standard_A4_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D11_v2'
  'Standard_D12_v2'
  'Standard_B2ms'
  'Standard_B2s'
  'Standard_B4ms'
])
param vmSize string = 'Standard_B2ms'

@description('The address range of the new virtual network in CIDR format')
param virtualNetworkAddressRange string = '10.0.0.0/16'

@description('The address range of the desired subnet for Active Directory.')
param adSubnetAddressRange string = '10.0.1.0/24'

@description('The IP Addresses assigned to the domain controllers (a, b). Remember the first IP in a subnet is .4 e.g. 10.0.0.0/16 reserves 10.0.0.0-3. Specify one IP per server - must match numberofVMInstances or deployment will fail.')
param adIP string = '10.0.1.4'

@description('The IP Addresses assigned to the AD FS servers (a, b). Remember the first IP in a subnet is .4 e.g. 10.0.0.0/16 reserves 10.0.0.0-3. Specify one IP per server - must match numberofVMInstances or deployment will fail.')
param adfsIP string = '10.0.1.8'

@description('The IP Addresses assigned to the ADCS servers (a, b). Remember the first IP in a subnet is .4 e.g.' )
param adcsIP string = '10.0.1.6'

@description('The address range of the desired subnet for the DMZ.')
param dmzSubnetAddressRange string = '10.0.2.0/24'

@description('The address range of the desired subnet for clients (Reserved for future use)')
param cliSubnetAddressRange string = '10.0.3.0/24'

@description('The address range of the desired subnet for Azure Bastion.')
param bastionSubnetAddressRange string = '10.0.4.0/26'

@description('The address range of the desired subnet for servers.')
param srvSubnetAddressRange string = '10.0.5.0/26'

@description('AdSrvToDeploy, possible values: 1-2.')
@allowed([
  1
  2
])
param AdSrvToDeploy int = 1


param location string = resourceGroup().location
param region string = 'sdc'

var automationaccountname = 'aa${uniqueString(resourceGroup().id)}'
var logAnalyticsWorkspaceName = 'la${uniqueString(resourceGroup().id)}'
var adfsDeployCount = int(AdfsFarmCount)
var networkInterfaceName = 'nic'
var addcVMNameSuffix = 'dc'
var adcsVMNameSuffix = 'cs'
var adfsVMNameSuffix = 'fs'
var wapVMNameSuffix = 'wap'
var companyNamePrefix = split(adDomainName, '.')[0]
var adfsVMName = toUpper('${companyNamePrefix}${adfsVMNameSuffix}')
var adVMName = toUpper('${companyNamePrefix}${addcVMNameSuffix}')
var adcsVMName = toUpper('${companyNamePrefix}${adcsVMNameSuffix}')
var adNSGName = 'nsg-int-ad'
var virtualNetworkName = 'vnet-${environmentName}-${region}-001'
var adSubnetName = 'snet-ad-${region}-001'
var bastionSubnetName = 'AzureBastionSubnet'
var bastionNSGName = 'nsg-bastion'
var dmzNSGName = 'nsg-dmz-wap'
var dmzSubnetName = 'snet-dmz-${region}-001'
var cliNSGName = 'nsg-int-cli'
var cliSubnetName = 'snet-client-${region}-001'
var srvNSGName = 'nsg-int-cli'
var srvSubnetName = 'snet-srv-${region}-001'
var publicIPAddressDNSName = toLower('${companyNamePrefix}-adfs-${uniqueString(resourceGroup().id)}')
var wapVMName = toUpper('${companyNamePrefix}${wapVMNameSuffix}')
//var adDSCTemplate = '${assetLocation}scripts/adDSCConfiguration.zip'
var DeployADFSFarmTemplate = 'InstallADFS.ps1'
var DeployADFSFarmTemplateUri = '${assetLocation}scripts/InstallADFS.ps1'
var CopyCertToWAPTemplate = 'CopyCertToWAP.ps1'
var CopyCertToWAPTemplateUri = '${assetLocation}scripts/CopyCertToWAP.ps1'
var InstallADCSTemplateUri = '${assetLocation}scripts/InstallADCS.ps1'
//var adDSCConfigurationFunction = 'adDSCConfiguration.ps1\\DomainController'
var subnets = [
  {
    name: adSubnetName
    properties: {
      addressprefix: adSubnetAddressRange
      networkSecurityGroup: {
        id: resourceId('Microsoft.Network/networkSecurityGroups', adNSGName)
      }
    }
  }
  {
    name: bastionSubnetName
    properties: {
      addressprefix: bastionSubnetAddressRange
      networkSecurityGroup: {
        id: resourceId('Microsoft.Network/networkSecurityGroups', bastionNSGName)
      }
    }
  }
  {
    name: dmzSubnetName
    properties: {
      addressprefix: dmzSubnetAddressRange
      natGateway: {
        id: natgw.outputs.natgwresourceId
      }
      networkSecurityGroup: {
        id: resourceId('Microsoft.Network/networkSecurityGroups', dmzNSGName)
      }
    }
  }
  {
    name: srvSubnetName
    properties: {
      addressprefix: srvSubnetAddressRange
      networkSecurityGroup: {
        id: resourceId('Microsoft.Network/networkSecurityGroups', srvNSGName)
      }
    }
  }
  {
    name: cliSubnetName
    properties: {
      addressprefix: cliSubnetAddressRange
      networkSecurityGroup: {
        id: resourceId('Microsoft.Network/networkSecurityGroups', cliNSGName)
      }
    }
  }
]
var adfsDSCTemplate = '${assetLocation}scripts/adfsDSC.zip'
var adfsDSCConfigurationFunction = 'adfsDSCConfiguration.ps1\\Main'
var wapDSCConfigurationFunction = 'wapDSCConfiguration.ps1\\Main'
var WAPPubIpDnsFQDN = '${publicIPAddressDNSName}{0}.${toLower(replace(location, ' ', ''))}.cloudapp.azure.com'

module automationaccount 'modules/automationaccount.bicep' = {
  name: 'automationaccount'
  params: {
    location: location
    automationaccountname: automationaccountname
  }
}

module virtualNetwork 'modules/networking/vnet.bicep' = {
  name: 'virtualNetwork'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    subnets: subnets
    virtualNetworkAddressRange: virtualNetworkAddressRange
    bastionSubnetAddressRange: bastionSubnetAddressRange
  }
  dependsOn: [
    NSGs
  ]
}

module NSGs 'modules/networking/vnet-nsg.bicep' = {
  name: 'NSGs'
  params: {
    location: location
    subnets: subnets
  }
}

module natgw 'modules/networking/nat-gw.bicep' = {
  name: 'natgw'
  params: {
    location: location
  }
  dependsOn: [
  ]
}

module adVMs 'modules/compute/vm-ad.bicep' = [for i in range(0, AdSrvToDeploy): {
  name: '${adVMName}${i}'
  params: {
    adIP: adIP
    adminPassword: adminPassword
    adminUsername: adminUsername
    adDomainName: adDomainName
    adSubnetName: adSubnetName
    adVMName: '${adVMName}${i}'
    location: location
    NetworkInterfaceName: networkInterfaceName
    virtualNetworkName: virtualNetworkName
    vmSize: vmSize
  }
  dependsOn: [
    NSGs
    virtualNetwork
    automationaccount
  ]
}]

module virtualNetworkDNSUpdate 'modules/networking/vnet-dns.bicep' = {
  name: 'virtualNetworkDNSUpdate'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    subnets: subnets
    virtualNetworkAddressRange: virtualNetworkAddressRange
    dnsIP: adIP
  }
  dependsOn: [
    adVMs
  ]
}

module adcsVM 'modules/compute/vm-adcs.bicep' = {
  name: 'adcsVM'
  params: {
    adcsIP: adcsIP
    adSubnetName: adSubnetName
    adcsVMName: adcsVMName
    adDomainName: adDomainName
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    NetworkInterfaceName: networkInterfaceName
    virtualNetworkName: virtualNetworkName
    vmSize: vmSize
  }
  dependsOn: [
    virtualNetworkDNSUpdate
    adfsVMs
  ]
}

module adfsVMs 'modules/compute/vm-adfs.bicep' = {
  name: 'adfsVMs'
  params: {
    adfsIP: adfsIP
    adSubnetName: adSubnetName
    adfsVMName: adfsVMName
    adDomainName: adDomainName
    adminPassword: adminPassword
    adminUsername: adminUsername
    dmzSubnetName: dmzSubnetName
    location: location
    NetworkInterfaceName: networkInterfaceName
    publicIPAddressDNSName: publicIPAddressDNSName
    virtualNetworkName: virtualNetworkName
    vmSize: vmSize
    wapVMName: wapVMName
    AdfsFarmCount: AdfsFarmCount
  }
  dependsOn: [
    virtualNetworkDNSUpdate
  ]
}

resource adfsVMName_1_InstallADFS 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = [for i in range(0, adfsDeployCount): {
  name: '${adfsVMName}${i}/InstallADFS'
  location: location
  tags: {
    displayName: 'DeployADFSFarm'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        DeployADFSFarmTemplateUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${DeployADFSFarmTemplate} -Acct ${adminUsername} -PW ${adminPassword} -WapFqdn ${WAPPubIpDnsFQDN}'
    }
  }
  dependsOn: [
    adfsVMs
  ]
}]

resource wapVMName_1_CopyCertToWAP 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = [for i in range(0, adfsDeployCount): {
  name: '${wapVMName}${i}/CopyCertToWAP'
  location: location
  tags: {
    displayName: 'ConfigureWAP'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        CopyCertToWAPTemplateUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${CopyCertToWAPTemplate} -DCFQDN ${adVMName}.${adDomainName} -adminuser ${adminUsername} -password ${adminPassword} -instance ${i} -WapFqdn ${WAPPubIpDnsFQDN}'
    }
  }
  dependsOn: [
    adfsVMs
    adfsVMName_1_InstallADFS
  ]
}]

resource adcsVMName_InstallADCS 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${adcsVMName}/InstallADCS'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        InstallADCSTemplateUri
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File InstallADCS.ps1'
    }
  }
  dependsOn: [
    adcsVM
    adfsVMName_1_InstallADFS
  ]
}

// Deploy the Microsoft Sentinel instance
module workspace 'modules/sentinel.bicep' = {
  name: 'microsoftSentinel'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    retentionInDays: logAnalyticsWorkspaceRetention
    sku: 'PerGB2018'
    dailyQuotaGb: logAnalyticsWorkspaceDailyQuota
  }
}

// Create data collection rule
resource dcr 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: 'DCR'
  location: location
  kind: 'Windows'
  tags: {
    createdBy: 'Sentinel'
  }
  properties: {
    dataFlows: [
      {
        destinations: [
          logAnalyticsWorkspaceName
        ]
        streams: [
          'Microsoft-SecurityEvent'
        ]
      }
    ]
    dataSources: {
      windowsEventLogs: [
        {
          name: 'windowsSecurityEventLogs'
          streams: [
            'Microsoft-SecurityEvent'
          ]
          xPathQueries: [
            'Security!*[System[(EventID=1) or (EventID=299) or (EventID=300) or (EventID=324) or (EventID=340) or (EventID=403) or (EventID=404) or (EventID=410) or (EventID=411) or (EventID=412) or (EventID=413) or (EventID=431) or (EventID=500) or (EventID=501) or (EventID=1100)]]'
            'Security!*[System[(EventID=1102) or (EventID=1107) or (EventID=1108) or (EventID=4608) or (EventID=4610) or (EventID=4611) or (EventID=4614) or (EventID=4622) or (EventID=4624) or (EventID=4625) or (EventID=4634) or (EventID=4647) or (EventID=4648) or (EventID=4649) or (EventID=4657)]]'
            'Security!*[System[(EventID=4661) or (EventID=4662) or (EventID=4663) or (EventID=4665) or (EventID=4666) or (EventID=4667) or (EventID=4688) or (EventID=4670) or (EventID=4672) or (EventID=4673) or (EventID=4674) or (EventID=4675) or (EventID=4689) or (EventID=4697) or (EventID=4700)]]'
            'Security!*[System[(EventID=4702) or (EventID=4704) or (EventID=4705) or (EventID=4716) or (EventID=4717) or (EventID=4718) or (EventID=4719) or (EventID=4720) or (EventID=4722) or (EventID=4723) or (EventID=4724) or (EventID=4725) or (EventID=4726) or (EventID=4727) or (EventID=4728)]]'
            'Security!*[System[(EventID=4729) or (EventID=4733) or (EventID=4732) or (EventID=4735) or (EventID=4737) or (EventID=4738) or (EventID=4739) or (EventID=4740) or (EventID=4742) or (EventID=4744) or (EventID=4745) or (EventID=4746) or (EventID=4750) or (EventID=4751) or (EventID=4752)]]'
            'Security!*[System[(EventID=4754) or (EventID=4755) or (EventID=4756) or (EventID=4757) or (EventID=4760) or (EventID=4761) or (EventID=4762) or (EventID=4764) or (EventID=4767) or (EventID=4768) or (EventID=4771) or (EventID=4774) or (EventID=4778) or (EventID=4779) or (EventID=4781)]]'
            'Security!*[System[(EventID=4793) or (EventID=4797) or (EventID=4798) or (EventID=4799) or (EventID=4800) or (EventID=4801) or (EventID=4802) or (EventID=4803) or (EventID=4825) or (EventID=4826) or (EventID=4870) or (EventID=4886) or (EventID=4887) or (EventID=4888) or (EventID=4893)]]'
            'Security!*[System[(EventID=4898) or (EventID=4902) or (EventID=4904) or (EventID=4905) or (EventID=4907) or (EventID=4931) or (EventID=4932) or (EventID=4933) or (EventID=4946) or (EventID=4948) or (EventID=4956) or (EventID=4985) or (EventID=5024) or (EventID=5033) or (EventID=5059)]]'
            'Security!*[System[(EventID=5136) or (EventID=5137) or (EventID=5140) or (EventID=5145) or (EventID=5632) or (EventID=6144) or (EventID=6145) or (EventID=6272) or (EventID=6273) or (EventID=6278) or (EventID=6416) or (EventID=6423) or (EventID=6424) or (EventID=8001) or (EventID=8002)]]'
            'Security!*[System[(EventID=8003) or (EventID=8004) or (EventID=8005) or (EventID=8006) or (EventID=8007) or (EventID=8222) or (EventID=26401) or (EventID=30004)]]'
            'Microsoft-Windows-AppLocker/EXE and DLL!*[System[(EventID=8001) or (EventID=8002) or (EventID=8003) or (EventID=8004)]]'
            'Microsoft-Windows-AppLocker/MSI and Script!*[System[(EventID=8005) or (EventID=8006) or (EventID=8007)]]'
            ]
        }
      ]
    }
    description: 'Data collection rule to collect common Windows security events.'
    destinations: {
      logAnalytics: [
        {
          name: logAnalyticsWorkspaceName
          workspaceResourceId: workspace.outputs.workspaceResourceId
        }
      ]
    }
  }
}

// Create a data collection rule association for the domain controller
resource domainControllerVm 'Microsoft.Compute/virtualMachines@2021-11-01' existing =[for i in range(0, AdSrvToDeploy): {
  name: '${adVMName}${i}'
}]

resource domainControllerAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01' = [for i in range(0, AdSrvToDeploy): {
  name: '${'adVMs'}${i}-dcra'
  dependsOn: [
    workspace
    adVMs
  ]
  scope: domainControllerVm[i]
  properties: {
    dataCollectionRuleId: dcr.id
  }
}]

resource kvRef 'Microsoft.KeyVault/vaults@2023-07-01' existing  = {
  name: keyvault.name

}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kvRef
  name: adminUsername
  properties: {
    value: adminPassword
  }
}
