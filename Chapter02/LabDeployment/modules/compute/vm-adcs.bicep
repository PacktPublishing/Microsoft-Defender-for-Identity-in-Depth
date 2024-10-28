@description('The IP Addresses assigned to the domain controllers (a, b). Remember the first IP in a subnet is .4 e.g. 10.0.0.0/16 reserves 10.0.0.0-3. Specify one IP per server - must match numberofVMInstances or deployment will fail.s')
param adcsIP string = '10.0.1.6'

@description('Admin password')
@secure()
param adminPassword string

@description('Admin username')
param adminUsername string

@description('Location of scripts')
param DeployADCSTemplateUri string = 'https://raw.githubusercontent.com/pthoor/microsoft-defender-for-identity-in-depth/main/Chapter01/LabDeployment/'

//@description('When deploying the stack N times, define the instance - this will be appended to some resource names to avoid collisions.')
//param deploymentNumber string = '1'

param adSubnetName string = 'adSubnet'
param adcsVMName string = 'AZADCS'
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
var adcsPubIPName = 'adcs-pip'
var adcsNicName = 'adcs-${NetworkInterfaceName}'
var shortDomainName = split(adDomainName, '.')[0]
var domainJoinOptions = 3

resource adcsPIPName 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: adcsPubIPName
  location: location
  tags: {
    displayName: 'adcsPubIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${adcsVMName}${uniqueString(resourceGroup().id)}')
    }
  }
}

resource adcs_NicName 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: adcsNicName
  location: location
  tags: {
    displayName: 'adNIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'adcsipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, adSubnetName)
          }
          privateIPAddress: adcsIP
          publicIPAddress: {
            id: adcsPIPName.id
          }
        }
      }
    ]
  }
}

resource adcsVMName_resource 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: adcsVMName
  location: location
  tags: {
    displayName: 'adcsVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: adcsVMName
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
          id: adcs_NicName.id
        }
      ]
    }
  }
  identity:{
    type: 'SystemAssigned'
  }
}

resource adcs_joindomain 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: 'joindomain'
  parent: adcsVMName_resource
  location: location
  tags: {
    displayName: 'adcsVMJoin'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: adDomainName
      OUPath: ''
      User: '${shortDomainName}\\${adminUsername}'
      Restart: 'true'
      Options: domainJoinOptions
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
}

resource guestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  parent: adcsVMName_resource
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
