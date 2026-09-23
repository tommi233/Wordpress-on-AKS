param clusterName string
param location string 
param kubernetesVersion string
param agentPoolSize string
param aksVirtualNetworkName string
param subnetId string
param nodeResourceGroupName string
param userPoolSize string
param clusterAuthorizedIPRanges array
param roleDefinitionId string = '4d97b98b-1d4f-4787-a291-c67834d212e7'

resource managedCluster 'Microsoft.ContainerService/managedClusters@2025-02-01' = {
  name: clusterName
  location: location
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${clusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 2
        vmSize: agentPoolSize
        osDiskSizeGB: 80
        osDiskType: 'Managed'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        minCount: 2
        maxCount: 4
        kubeletDiskType: 'OS'
        vnetSubnetID: subnetId
        enableAutoScaling: true
        enableFIPS: false
        enableEncryptionAtHost: false
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        scaleSetPriority: 'Regular'
        scaleSetEvictionPolicy: 'Delete'
        orchestratorVersion: kubernetesVersion  
        enableNodePublicIP: false
        maxPods: 50
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        upgradeSettings: {
          maxSurge: '33%'
        }
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'userpool'
        count: 2
        vmSize: userPoolSize
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        kubeletDiskType: 'OS'
        minCount: 2
        maxCount: 4
        vnetSubnetID: subnetId
        enableAutoScaling: true
        enableFIPS: false
        enableEncryptionAtHost: false
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        scaleSetPriority: 'Regular'
        scaleSetEvictionPolicy: 'Delete'
        orchestratorVersion: kubernetesVersion
        enableNodePublicIP: false
        maxPods: 30
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        upgradeSettings: {
          maxSurge: '33%'
        }
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
      azurepolicy: {
        enabled: true
      }
    }
    nodeResourceGroup: nodeResourceGroupName
    enableRBAC: true
    enablePodSecurityPolicy: false
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      podCidr: '192.168.0.0/16'
      networkPolicy: 'none'
      loadBalancerSku: 'Standard'
      loadBalancerProfile: null
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
      outboundType: 'loadBalancer'
    }
    autoScalerProfile: {
      'balance-similar-node-groups': 'false'
      expander: 'random'
      'max-empty-bulk-delete': '10'
      'max-graceful-termination-sec': '600'
      'max-node-provision-time': '15m'
      'max-total-unready-percentage': '45'
      'new-pod-scale-up-delay': '0s'
      'ok-total-unready-count': '3'
      'scale-down-delay-after-add': '10m'
      'scale-down-delay-after-delete': '10s'
      'scale-down-delay-after-failure': '3m'
      'scale-down-unneeded-time': '10m'
      'scale-down-unready-time': '20m'
      'scale-down-utilization-threshold': '0.5'
      'scan-interval': '10s'
      'skip-nodes-with-local-storage': 'false'
      'skip-nodes-with-system-pods': 'true'
    }
    apiServerAccessProfile: {
      authorizedIPRanges: clusterAuthorizedIPRanges
      enablePrivateCluster: false
    }
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    azureMonitorProfile: {
      metrics: {
        enabled: true
        kubeStateMetrics: {}
      }
    }
    storageProfile: {
      blobCSIDriver: {
        enabled: false
      }
      diskCSIDriver: {
        enabled: false
      }
      fileCSIDriver: {
        enabled: false
      }
      snapshotController: {
        enabled: false
      }
    }
    disableLocalAccounts: false
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      imageCleaner: {
        enabled: true
        intervalHours: 168
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    metricsProfile: {
      costAnalysis: {
        enabled: false
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
}

resource aksVirtualnetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: aksVirtualNetworkName
}

resource aksClusterNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(roleDefinitionId, resourceGroup().id)
  scope: aksVirtualnetwork
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: managedCluster.identity.principalId
  }
}


