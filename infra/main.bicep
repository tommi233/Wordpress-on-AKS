targetScope = 'subscription'
var location string = deployment().location

@description('Name of the workload')
param workloadName string
@description('Alias for the location, used to create unique resource names.')
param locationAlias string
var resourceGroupName string = 'rg-aks-${workloadName}-${locationAlias}'

var virtualNetworkName string = 'vnet-aks-${workloadName}-${locationAlias}'
var vnetAddrPrefix string = '10.100.0.0/24'

// Subnets //
var aksSubnetName string = 'snet-clusternodes-aks'
var aksSubnetAddrPrefix string = '10.100.0.0/26'
var appgatewaySubnetName string = 'snet-agw-aks'
var appgatewaySubnetAddrPrefix string = '10.100.0.64/26'
var privateLinkSubnetName string = 'snet-pep-aks'
var privateLinkSubnetAddrPrefix string = '10.100.0.128/28'
var netappSubnetName string = 'snet-netapp-aks'
var netappSubnetAddrPrefix string = '10.100.0.144/28'

var mysqlPrivateEndpointName string = 'pe-mysql-${workloadName}-${locationAlias}'
var mySqlDnsZoneName = 'privatelink.mysql.database.azure.com'

// MySQL Database //
var sqlServerName string = 'sql-${workloadName}-${locationAlias}'
param sqlAdministratorLogin string
@secure()
param sqlAdministratorLoginPassword string
var databaseName string = 'db-${workloadName}-${locationAlias}'
var sqlVersion string = '8.0.21'
var sqlServerSKU string = 'Standard_B1ms'

// AKS Cluster //
var aksClusterName string = 'aks-${workloadName}-${locationAlias}'
var kubernetesVersion string = '1.35.7'
var agentPoolSize string = 'Standard_D4as_v5'
var userPoolSize string = 'Standard_D4as_v5'
var clusterAuthorizedIPRanges array = []
var nodeResourceGroupName string = 'MC_rg-aks-itn_${aksClusterName}_italynorth'

// NetApp Files //
var netappAccountName string = 'netapp-${workloadName}-${locationAlias}'
var capacityPoolName string = 'pool-${workloadName}-${locationAlias}'
var volumeName string = 'vol-${workloadName}-${locationAlias}'
var serviceLevel string = 'Premium'
var numberOfTB int = 1
var qosType string = 'Auto'
var numberOf50GB int = 1

// Key Vault //
var keyVaultPrivateEndpointName string = 'pe-kv-${workloadName}-${locationAlias}'
var keyVaultDnsZoneName = 'privatelink.vaultcore.azure.net'
var uniqueStr = uniqueString(subscription().id)
var uniqueId = take(uniqueStr, 8) 
var keyVaultName string = 'kv-${workloadName}-${uniqueId}-${locationAlias}'

// Application Gateway //
var applicationGatewayPublicIpAddressName string = 'agw-pip-${workloadName}-${locationAlias}'
var applicationGatewayName string = 'agw-${workloadName}-${locationAlias}'

var internalLoadBalancerIp string = '10.100.0.62'
var subnets = [
  {
    subnetAddrPrefix: aksSubnetAddrPrefix

    subnetName: aksSubnetName
    vnetName: virtualNetworkName
    nsgId: nsgClusterSubnet.outputs.networkSecurityGroupId
    routeTableId: ''
    delegation: ''
  }
  {
    subnetAddrPrefix: appgatewaySubnetAddrPrefix
    subnetName: appgatewaySubnetName
    vnetName: virtualNetworkName
    nsgId: nsgAppGatewaySubnet.outputs.networkSecurityGroupId
    routeTableId: ''
    delegation: ''
  }
  {
    subnetAddrPrefix: privateLinkSubnetAddrPrefix
    subnetName: privateLinkSubnetName
    vnetName: virtualNetworkName
    nsgId: nsgPrivateLinkSubnet.outputs.networkSecurityGroupId
    routeTableId: ''
    delegation: ''
  }
  {
    subnetAddrPrefix: netappSubnetAddrPrefix
    subnetName: netappSubnetName
    vnetName: virtualNetworkName
    nsgId: nsgNetAppSubnet.outputs.networkSecurityGroupId
    routeTableId: ''
    delegation: 'Microsoft.NetApp/volumes'
  }
]

module aksResourceGroup './modules/resourcegroup.bicep' = {
  name: 'aksResourceGroup'
  params: {
    location: location
    rgName: resourceGroupName
  }
}

module aksVirtualnetwork 'modules/virtualnetwork.bicep' = {
  name: 'aksVirtualnetwork'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    vnetName: virtualNetworkName
    vnetAddrPrefix: vnetAddrPrefix
    subnets: subnets
  }
  dependsOn: [
    aksResourceGroup
  ]
}
/*
module mysql './modules/mysql.bicep' = {
  name: 'mysql'
  scope: resourceGroup(resourceGroupName)
  params: {
    sqlServerName: sqlServerName
    location: location
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    sqlVersion: sqlVersion
    databaseName: databaseName
    sqlServerSKU: sqlServerSKU
  }
  dependsOn: [
    aksResourceGroup
  ]
}

module mySqlPrivateDnsZone './modules/privatednszone.bicep' = {
  name: 'mySqlPrivateDnsZone'
  scope: resourceGroup(resourceGroupName)
  params: {
    dnsZoneName: mySqlDnsZoneName
    virtualNetworkName: virtualNetworkName
    virtualNetworkId: aksVirtualnetwork.outputs.vnetId
  }
  dependsOn: [
    aksResourceGroup
  ]
}

module mySQLPrivateEndpoint './modules/privateendpoint.bicep' = {
  name: 'mySQLPrivateEndpoint'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    privateEndpointName: mysqlPrivateEndpointName
    subnetPrivateEndpointId: aksVirtualnetwork.outputs.privateLinkSubnetId
    linkedResourceId: mysql.outputs.sqlServerId
    serviceName: 'mysqlServer'
    privateDnsZoneId: mySqlPrivateDnsZone.outputs.dnsZoneId
    virtualNetworkName: virtualNetworkName
  }
  dependsOn: [
    aksResourceGroup
  ]
}
*/

module aksCluster './modules/akscluster.bicep' = {
  name: 'aksCluster'
  scope: resourceGroup(resourceGroupName)
  params: {
    clusterName: aksClusterName
    location: location
    kubernetesVersion: kubernetesVersion
    agentPoolSize: agentPoolSize
    userPoolSize: userPoolSize
    aksVirtualNetworkName: virtualNetworkName
    subnetId: aksVirtualnetwork.outputs.aksSubnetId
    clusterAuthorizedIPRanges: clusterAuthorizedIPRanges
    nodeResourceGroupName: nodeResourceGroupName
  }
}
/*
module netapp './modules/netapp.bicep' = {
  name: 'netapp'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    netappAccountName: netappAccountName
    capacityPoolName: capacityPoolName
    volumeName: volumeName
    serviceLevel: serviceLevel
    numberOfTB: numberOfTB
    qosType: qosType
    numberOf50GB: numberOf50GB
    netappSubnetId: aksVirtualnetwork.outputs.netappSubnetId
    aksSubnetAddrPrefix: aksSubnetAddrPrefix
  }
  dependsOn: [
    aksResourceGroup
  ]
}
*/
module appGatewayPublicIpAddress './modules/publicipaddress.bicep' = {
  name: 'appGatewayPublicIpAddress'
  scope: resourceGroup(resourceGroupName)
  params: {
    publicIpAddressName: applicationGatewayPublicIpAddressName
    location: location
  }
  dependsOn: [
    aksResourceGroup
  ]
}

module applicationGateway './modules/applicationgateway.bicep' = {
  name: 'applicationGateway'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    applicationGatewayName: applicationGatewayName
    applicationGatewaySubnetId: aksVirtualnetwork.outputs.appGatewaySubnetId
    appGatewayPublicIpAddressId: appGatewayPublicIpAddress.outputs.publicIpAddressId
    internalLoadBalancerIp: internalLoadBalancerIp
  }
  dependsOn: [
    aksResourceGroup
  ]
}


module keyVaultPrivateEndpoint './modules/privateendpoint.bicep' = {
  name: 'keyVaultPrivateEndpoint'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    privateEndpointName: keyVaultPrivateEndpointName
    subnetPrivateEndpointId: aksVirtualnetwork.outputs.privateLinkSubnetId
    linkedResourceId: keyVault.outputs.keyVaultId
    serviceName: 'vault'
    privateDnsZoneId: keyVaultPrivateDnsZone.outputs.dnsZoneId
    virtualNetworkName: virtualNetworkName
  }
  dependsOn: [
    aksResourceGroup
  ]
}

module keyVaultPrivateDnsZone './modules/privatednszone.bicep' = {
  name: 'KeyVaultPrivateDnsZone'
  scope: resourceGroup(resourceGroupName)
  params: {
    dnsZoneName: keyVaultDnsZoneName
    virtualNetworkName: virtualNetworkName
    virtualNetworkId: aksVirtualnetwork.outputs.vnetId
  }
  dependsOn: [
    aksResourceGroup
  ]
}

module keyVault './modules/keyvault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup(resourceGroupName)
  params: {
    keyVaultName: keyVaultName
    location: location
    mySqlConnectionString: ''
    mySqlUser: sqlAdministratorLogin
    mySqlPassword: sqlAdministratorLoginPassword
    mySqlDBName: databaseName
    aksClusterName: aksClusterName
    nodeResourceGroupName: nodeResourceGroupName
  }
  dependsOn: [
    aksResourceGroup
    keyVaultPrivateDnsZone
  ]
}

module nsgClusterSubnet './modules/networksecuritygroup.bicep' = {
  name: 'nsgClusterSubnet'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    networkSecurityGroupName: 'nsg-${aksSubnetName}'
    securityRules: []
  }
  dependsOn: [
    aksResourceGroup
  ]
}
//TODO: Add NSG rules for subnets
module nsgPrivateLinkSubnet './modules/networksecuritygroup.bicep' = {
  name: 'nsgPrivateLinkSubnet'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    networkSecurityGroupName: 'nsg-${privateLinkSubnetName}'
    securityRules: []
  }
  dependsOn: [
    aksResourceGroup
  ]
}

module nsgAppGatewaySubnet './modules/networksecuritygroup.bicep' = {
  name: 'nsgAppGatewaySubnet'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    networkSecurityGroupName: 'nsg-${appgatewaySubnetName}'
    securityRules: [
      {
        name: 'Allow443Inbound'
        properties: {
          description: ''
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: 'VirtualNetwork'
          direction: 'Inbound'
          access: 'Allow'
          priority: 110
        }
      }
      {
        name: 'Allow80Inbound'
        properties: {
          description: ''
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '80'
          destinationAddressPrefix: 'VirtualNetwork'
          direction: 'Inbound'
          access: 'Allow'
          priority: 100
        }
      }
      {
        name: 'AllowControlPlaneInbound'
        properties: {
          description: ''
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '65200-65535'
          destinationAddressPrefix: '*'
          direction: 'Inbound'
          access: 'Allow'
          priority: 120
        }
      }
      {
        name: 'AllowHealthProbesInbound'
        properties: {
          description: ''
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          direction: 'Inbound'
          access: 'Allow'
          priority: 130
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'No further inbound traffic allowed.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAllOutbound'
        properties: {
          description: ''
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
  dependsOn: [
    aksResourceGroup
  ]
}

module nsgNetAppSubnet './modules/networksecuritygroup.bicep' = {
  name: 'nsgNetAppSubnet'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    networkSecurityGroupName: 'nsg-${netappSubnetName}'
    securityRules: []
  }
  dependsOn: [
    aksResourceGroup
  ]
}
