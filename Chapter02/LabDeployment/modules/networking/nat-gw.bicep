@description('Name of resource group')
param location string = resourceGroup().location

@description('Name of the NAT gateway')
param natgatewayname string = 'nat-gateway'

@description('Name of the NAT gateway public IP')
param publicipname string = 'nat-pip'

resource publicip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicipname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource natgateway 'Microsoft.Network/natGateways@2021-05-01' = {
  name: natgatewayname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicip.id
      }
    ]
  }
}

output natgwname string = natgateway.name
output natgwresourceId string = natgateway.id
