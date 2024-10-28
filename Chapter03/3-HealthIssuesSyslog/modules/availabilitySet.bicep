param location string

@description('Format string of the resource names.')
param resourceNameFormat string = '{0}-syslog'

resource ppg 'Microsoft.Compute/proximityPlacementGroups@2021-04-01' = {
  name: format(resourceNameFormat, 'ppg')
  location: location
  properties: {
    proximityPlacementGroupType: 'Standard'
  }
}

resource avset 'Microsoft.Compute/availabilitySets@2021-04-01' = {
  name: format(resourceNameFormat, 'avail')
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 2
    proximityPlacementGroup: {
      id: ppg.id
    }
  }
}

output avsetId string = avset.id
