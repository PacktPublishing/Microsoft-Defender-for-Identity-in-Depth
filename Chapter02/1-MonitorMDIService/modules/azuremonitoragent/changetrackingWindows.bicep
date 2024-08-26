param vmName string
param location string = resourceGroup().location

resource virtualMachineName_ctExtensionProperties_virtualMachineOsType_type 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  name: '${vmName}/ChangeTracking-Windows'
  location: location
  properties: {
  publisher: 'Microsoft.Azure.ChangeTrackingAndInventory'
    type: 'ChangeTracking-Windows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
  }
}
