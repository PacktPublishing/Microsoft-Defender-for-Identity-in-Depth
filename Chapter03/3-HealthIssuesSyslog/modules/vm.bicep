param location string

@description('The name of the virtual machine')
param vmName string

@description('The name of the network interface card')
param nicName string

@description('Name of the Azure virtual network where the virtual machines needs to be deployed')
param virtualNetworkName string

@description('The name of the Resource Group containing the Virtual Network')
param virtualNetworkResourceGroup string

@description('Name of the virtual network subnet where the virtual machines should be created')
param subnetName string

@description('The Azure resource ID of the backend pool of the internal load balancer')
param lbiBackendAddressPoolId string

@description('The GUID of the Log Analytics workspace (with Sentinel) where the syslog will forward events to')
param workspaceId string

@description('Log Analytics workspace key')
@secure()
param workspaceKey string

@description('Password for the local user account')
@secure()
param adminPasswordOrKey string

param avsetId string = ''

param adminUserName string
param vmSize string = 'Standard_D2s_v5'

@description('The storage account type for the OS and data disks')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param storageAccountType string

@description('The name of the OS disk')
param osDiskName string

@description('The size of the OS disk in GB')
@allowed([
  30
  32
  64
  128
  256
])
param osDiskSize int

@description('The name of the data disk')
param dataDiskName string

@description('The size of the data disk in GB')
@allowed([
  32
  64
  128
  256
  512
  1024
])
param dataDiskSize int

@allowed([
  'ssh'
  'password'
])
param authenticationType string

@description('The image reference and filename of the OS configuration script which contains syslog configuration')
param osDetail object = {
  imageReference: {
    publisher: 'canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '22_04-lts'
    version: 'latest'
  }
  configScriptName: 'ubuntu_config.sh'
}

@description('The URL of the configuration scripts')
param scriptsLocation string
param scriptsLocationAccessToken string = ''

var linuxSshConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUserName}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var configScript = uri('${scriptsLocation}${osDetail.configScriptName}', '${scriptsLocationAccessToken}')

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: subnetName
  parent: vnet
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
          loadBalancerBackendAddressPools: empty(lbiBackendAddressPoolId) ? null : [
            {
              id: lbiBackendAddressPoolId
            }
          ]
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    availabilitySet: empty(avsetId) ? null : {
      id: avsetId
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: osDetail.imageReference
      osDisk: {
        name: osDiskName
        osType: 'Linux'
        diskSizeGB: osDiskSize
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: storageAccountType
        }
        deleteOption: 'Delete'
      }
      dataDisks: [
        {
          name: dataDiskName
          lun: 0
          diskSizeGB: dataDiskSize
          createOption: 'Empty'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: storageAccountType
          }
          deleteOption: 'Delete'
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxSshConfiguration)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource UbuntuConfigScript 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: 'syslog-ConfigScript'
  parent: vm
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    protectedSettings: {
      commandToExecute: 'bash ${osDetail.configScriptName} -w ${workspaceId} -k ${workspaceKey}'
      fileUris: [
        configScript
      ]
    }
  }
}
