param adSubnetName string = 'adSubnet'
param adfsVMName string = 'AZADFS'

@description('The IP Addresses assigned to the domain controllers (a, b). Remember the first IP in a subnet is .4 e.g. 10.0.0.0/16 reserves 10.0.0.0-3. Specify one IP per server - must match numberofVMInstances or deployment will fail.s')
param adfsIP string = '10.0.1.8'
param adDomainName string = 'contoso.local'

@description('Admin password')
@secure()
param adminPassword string

@description('Admin username')
param adminUsername string

//@description('When deploying the stack N times, define the instance - this will be appended to some resource names to avoid collisions.')
//param deploymentNumber string = '1'

param dmzSubnetName string = 'adSubnet'

@metadata({ Description: 'The region to deploy the resources into' })
param location string

@description('This is the prefix name of the Network interfaces')
param NetworkInterfaceName string = 'NIC'
param publicIPAddressDNSName string
param virtualNetworkName string = 'vnet'

@description('This is the allowed list of VM sizes')
param vmSize string = 'Standard_B2ms'
param wapVMName string = 'AZPROX'

@description('An ADFS/WAP server combo will be setup independently this number of times. NOTE: it\'s unlikely to ever need more than one - additional farm counts are for edge case testing.')
@allowed([
  '1'
  '2'
  '3'
  '4'
  '5'
])
param AdfsFarmCount string = '1'

var adfsDeployCount = int(AdfsFarmCount)
var shortDomainName = split(adDomainName, '.')[0]
var adfsNetworkArr = split(adfsIP, '.')
var adfsStartIpNodeAddress = int(adfsNetworkArr[3])
var adfsNetworkString = '${adfsNetworkArr[0]}.${adfsNetworkArr[1]}.${adfsNetworkArr[2]}.'
var adfsNICName = 'adfs-${NetworkInterfaceName}'
var adfsPubIpName = 'adfs-pip'
var domainJoinOptions = '3'
var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var imageSKU = '2022-Datacenter'
var wapNICName = 'wap-${NetworkInterfaceName}'
var wapPubIpName = 'wap-pip'

resource adfsPubIpName_1 'Microsoft.Network/publicIPAddresses@2022-07-01' = [for i in range(0, adfsDeployCount): {
  name: '${adfsPubIpName}${i}'
  location: location
  tags: {
    displayName: 'adfsPubIp'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${adfsVMName}${uniqueString(resourceGroup().id)}')
    }
  }
}]

resource wapPubIpName_1 'Microsoft.Network/publicIPAddresses@2022-07-01' = [for i in range(0, adfsDeployCount): {
  name: '${wapPubIpName}${i}'
  location: location
  tags: {
    displayName: 'wapPubIp'
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${publicIPAddressDNSName}${i}')
    }
  }
}]

resource adfsNICName_1 'Microsoft.Network/networkInterfaces@2022-07-01' = [for i in range(0, adfsDeployCount): {
  name: '${adfsNICName}${i}'
  location: location
  tags: {
    displayName: 'adfsNIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'adfsipconfig${i}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddress: '${adfsNetworkString}${adfsStartIpNodeAddress}'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${adfsPubIpName}${i}')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, adSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    adfsPubIpName_1
  ]
}]

resource wapNICName_1 'Microsoft.Network/networkInterfaces@2022-07-01' = [for i in range(0, adfsDeployCount): {
  name: '${wapNICName}${i}'
  location: location
  tags: {
    displayName: 'wapNIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'wapipconfig${i}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${wapPubIpName}${i}')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, dmzSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    wapPubIpName_1
  ]
}]

resource adfsVMName_1 'Microsoft.Compute/virtualMachines@2022-08-01' = [for i in range(0, adfsDeployCount): {
  name: '${adfsVMName}${i}'
  location: location
  tags: {
    displayName: 'adfsVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${adfsVMName}${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
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
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${adfsNICName}${i}')
        }
      ]
    }
  }
  dependsOn: [
    adfsNICName_1
  ]
}]

resource adfsVMName_1_joindomain 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = [for i in range(0, adfsDeployCount): {
  name: '${adfsVMName}${i}/joindomain'
  location: location
  tags: {
    displayName: 'adfsVMJoin'
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
  dependsOn: [
    adfsVMName_1
  ]
}]

resource wapVMName_1 'Microsoft.Compute/virtualMachines@2022-08-01' = [for i in range(0, adfsDeployCount): {
  name: '${wapVMName}${i}'
  location: location
  tags: {
    displayName: 'wapVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${wapVMName}${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
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
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${wapNICName}${i}')
        }
      ]
    }
  }
  dependsOn: [
    wapNICName_1
  ]
}]
