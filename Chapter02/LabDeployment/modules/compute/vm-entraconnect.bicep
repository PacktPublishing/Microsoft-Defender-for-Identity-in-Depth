@description('The IP Addresses assigned to the domain controllers (a, b). Remember the first IP in a subnet is .4 e.g. 10.0.0.0/16 reserves 10.0.0.0-3. Specify one IP per server - must match numberofVMInstances or deployment will fail.s')
param ecIP string = '10.0.1.10'

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
param ecVMName string
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
var ecPubIPName = 'ec-pip'
var ecNicName = 'ec-${NetworkInterfaceName}'
var shortDomainName = split(adDomainName, '.')[0]
var domainJoinOptions = 3

resource ecPIPName 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: ecPubIPName
  location: location
  tags: {
    displayName: 'ecPubIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${ecVMName}${uniqueString(resourceGroup().id)}')
    }
  }
}

resource ec_NicName 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: ecNicName
  location: location
  tags: {
    displayName: 'ecNIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ecipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, adSubnetName)
          }
          privateIPAddress: ecIP
          publicIPAddress: {
            id: ecPIPName.id
          }
        }
      }
    ]
  }
}

resource ecVMName_resource 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: ecVMName
  location: location
  tags: {
    displayName: 'adVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: ecVMName
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
          id: ec_NicName.id
        }
      ]
    }
  }
  identity:{
    type: 'SystemAssigned'
  }
}

resource ecVMName_joindomain 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: 'joindomain'
  parent: ecVMName_resource
  location: location
  tags: {
    displayName: 'ecVMJoin'
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
  parent: ecVMName_resource
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

