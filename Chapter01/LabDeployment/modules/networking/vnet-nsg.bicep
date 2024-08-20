@description('Name of the virtual network for this deployment')
//param virtualNetworkName string
param subnets array

param location string = resourceGroup().location

var var_adNSGName = 'nsg-int-ad'
var var_dmzNSGName = 'nsg-dmz-wap'
var var_bastionNSGName = 'nsg-bastion'
var var_cliNSGName = 'nsg-int-cli'
var adsubnetrange = subnets[0].properties.addressPrefix
var bastionSubnetRange = subnets[1].properties.addressPrefix
var dmzSubnetRange = subnets[2].properties.addressPrefix
var srvSubnetRange = subnets[3].properties.addressPrefix
var cliSubnetRange = subnets[4].properties.addressPrefix

resource adNSGName 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: var_adNSGName
  location: location
  tags: {
    displayName: 'adNSG'
  }
  properties: {
    securityRules: [
      {
        name: 'deny_RDP_from_DMZ'
        properties: {
          description: 'deny RDP to AD Servers from DMZ'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: dmzSubnetRange
          destinationAddressPrefix: adsubnetrange
          access: 'Deny'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_bastion_to_AD'
        properties: {
          description: 'Allow Bastion to AD Servers'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: bastionSubnetRange
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 111
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_RDP_to_AD_Servers'
        properties: {
          description: 'Allow RDP to AD Servers'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_SMTP'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '25'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 121
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_WINS'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '42'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 122
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_Repl'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '135'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 123
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_NetBIOS'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '137'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 124
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_netlogin'
        properties: {
          description: 'Allow AD Communication - DFSN, NetBIOS Session, NetLogon'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '139'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 125
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_LDAP'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '389'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 126
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_LDAP_udp'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '389'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 127
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_LDAPS'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '636'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 128
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_LDAP_GC'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3268-3269'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 129
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_KRB'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '88'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_KRB_udp'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '88'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 131
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_DNS'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 132
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_DNS_udp'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 133
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_445'
        properties: {
          description: 'Allow AD Communication - SMB, CIFS,SMB2, DFSN, LSARPC, NbtSS, NetLogonR, SamR, SrvSvc'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 134
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_445_udp'
        properties: {
          description: 'Allow AD Communication - SMB, CIFS,SMB2, DFSN, LSARPC, NbtSS, NetLogonR, SamR, SrvSvc'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 135
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_SOAP'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9389'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 136
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_DFSR'
        properties: {
          description: 'Allow AD Communication - DFSR/Sysvol'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5722'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 137
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_KRB2'
        properties: {
          description: 'Allow AD Communication - Kerberos change/set password'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '464'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 138
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_KRB2_udp'
        properties: {
          description: 'Allow AD Communication - Kerberos change/set password'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '464'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 139
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_time'
        properties: {
          description: 'Allow AD Communication - Windows Time Protocol'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '123'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_auth'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '137-138'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 141
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_ephemeral'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '49152-65535'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 142
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_AD_ephemeral_udp'
        properties: {
          description: 'Allow AD Communication'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '49152-65535'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 143
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_AD_Other_TCP'
        properties: {
          description: 'deny remainder of Communications'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: adsubnetrange
          access: 'Deny'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_AD_Other_UDP'
        properties: {
          description: 'deny remainder of Communications'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: adsubnetrange
          access: 'Deny'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_HTTPS_vNet'
        properties: {
          description: 'Allow app proxy communication from DMZ'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 199
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_WinRM_vNet'
        properties: {
          description: 'Allow WinRM sessions within the vNet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5985-5986'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: adsubnetrange
          access: 'Allow'
          priority: 198
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource DMZNSGName 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: var_dmzNSGName
  location: location
  tags: {
    displayName: 'DMZNSG'
  }
  properties: {
    securityRules: [
      {
        name: 'allow_HTTPS_from_Internet'
        properties: {
          description: 'Allow communication between Internet-facing LB and WAP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: dmzSubnetRange
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_RDP_from_VNet'
        properties: {
          description: 'Allow communication from internal vNet to DMZ'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: dmzSubnetRange
          access: 'Allow'
          priority: 103
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource bastionNSGName 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: var_bastionNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource cliNSGName 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: var_cliNSGName
  location: location
  tags: {
    displayName: 'CLINSG'
  }
  properties: {
    securityRules: [
      {
        name: 'allow_to_Internet'
        properties: {
          description: 'Allow communication out to Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: cliSubnetRange
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
        }
      }
      {
        name: 'allow_all_from_AD'
        properties: {
          description: 'Allow communication in from AD'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: adsubnetrange
          destinationAddressPrefix: cliSubnetRange
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_RDP'
        properties: {
          description: 'Allow communication from internet to client subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: cliSubnetRange
          access: 'Allow'
          priority: 103
          direction: 'Inbound'
        }
      }
    ]
  }
}
