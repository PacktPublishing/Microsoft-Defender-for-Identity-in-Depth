// Enable Azure Monitor Agent on Azure Windows VM with System Assigned Managed Identity
// User Assigned Managed Identity is the recommended approach for production workloads, see https://learn.microsoft.com/en-us/azure/azure-monitor/agents/resource-manager-agent?tabs=bicep#azure-monitor-agent

param vmName string
param location string

resource windowsAgent 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: '${vmName}/AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}
