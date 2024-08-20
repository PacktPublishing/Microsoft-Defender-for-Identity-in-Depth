@description('The IP Addresses assigned to the domain controllers (a, b). Remember the first IP in a subnet is .4 e.g. 10.0.0.0/16 reserves 10.0.0.0-3. Specify one IP per server - must match numberofVMInstances or deployment will fail.s')
param adIP string = '10.0.1.4'

@description('Admin password')
@secure()
param adminPassword string

@description('Admin username')
param adminUsername string

@description('Location of scripts')
param DeployADTemplateUri string = 'https://raw.githubusercontent.com/pthoor/deploy-azure/main/active-directory-with-windows-client/'

//@description('When deploying the stack N times, define the instance - this will be appended to some resource names to avoid collisions.')
//param deploymentNumber string = '1'

param adSubnetName string = 'adSubnet'
param adVMName string = 'AZAD'
param adDomainName string = 'contoso.local'

@metadata({ Description: 'The region to deploy the resources into' })
param location string

@description('This is the prefix name of the Network interfaces')
param NetworkInterfaceName string = 'NIC'
param virtualNetworkName string = 'vnet'

@description('This is the allowed list of VM sizes')
param vmSize string = 'Standard_B2ms'

var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var imageSKU = '2022-datacenter'
var adPubIPName = 'ad-pip'
var adNicName = 'ad-${NetworkInterfaceName}'

resource adPIPName 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: adPubIPName
  location: location
  tags: {
    displayName: 'adPubIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${adVMName}${uniqueString(resourceGroup().id)}')
    }
  }
}

resource ad_NicName 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: adNicName
  location: location
  tags: {
    displayName: 'adNIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'adipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, adSubnetName)
          }
          privateIPAddress: adIP
          publicIPAddress: {
            id: adPIPName.id
          }
        }
      }
    ]
  }
}

resource adVMName_resource 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: adVMName
  location: location
  tags: {
    displayName: 'adVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: adVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ad_NicName.id
        }
      ]
    }
  }
  identity:{
    type: 'SystemAssigned'
  }
}

resource adVMName_DeployAD 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${adVMName}/DeployAD'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(DeployADTemplateUri, 'scripts/SetupADDS.ps1')
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File SetupADDS.ps1 -domainName ${adDomainName} -domainAdminUsername ${adminUsername} -domainAdminPassword ${adminPassword} -templateBaseUrl ${DeployADTemplateUri}'
    }
  }
  dependsOn: [
    adVMName_resource
  ]
}

resource guestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  parent: adVMName_resource
  name: 'AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

//resource adVMName_DeployUsersComputers 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
//  name: '${adVMName}/DeployUsersComputers'
//  location: location
//  properties: {
//    publisher: 'Microsoft.Compute'
//    type: 'CustomScriptExtension'
//    typeHandlerVersion: '1.10'
//    autoUpgradeMinorVersion: true
//    settings: {
//      fileUris: [
//        uri(DeployADTemplateUri, 'scripts/PopulateAD.ps1')
//      ]
//      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File PopulateAD.ps1; Invoke-LoadADObjects -DomainName ${adDomainName} -LimitUsers 100'
//    }
//  }
//  dependsOn: [
//    adVMName_resource
//    adVMName_DeployAD
//    guestConfigExtension
//  ]
//}
