param location string
param adminGroupObjectID string
param tags object
param aksVersion string
param vmSku string = 'Standard_D4ds_v5'
param addressPrefix string
param sshPublicKey string
param userName string = 'localadmin'
param dnsPrefix string

var suffix = uniqueString(resourceGroup().id)

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    suffix: suffix
    tags: tags
    location: location
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    suffix: suffix
    tags: tags
    addressPrefix: addressPrefix
    location: location
  }
}

module acr './modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    location: location
    suffix: suffix
    tags: tags
  }
}

module aks './modules/aks.bicep' = {
  name: 'aksDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    location: location
    suffix: suffix
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksDockerBridgeCIDR: '172.17.0.1/16'
    aksServiceCIDR: '10.100.0.0/16'
    aksDnsPrefix: dnsPrefix
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    aksVersion: aksVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectID
    addOns: {
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: wks.outputs.workspaceId
        }
      }
    }
  }
}

module redis 'modules/redis.bicep' = {
  name: 'redisDeploy'
  params: {
    location: location
    suffix: suffix
    name: 'Premium'
    capacity: 1
    vnetName: vnet.outputs.name
  }
}

resource networkContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'Network Contributor', resourceGroup().id)
  properties: {
    principalId: aks.outputs.systemManagedIdentityPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  }
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'ACR Pull', resourceGroup().id)
  properties: {
    principalId: aks.outputs.kubeletIdentityObjectId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

output aksClusterName string = aks.outputs.aksClusterName
output aksClusterFqdn string = aks.outputs.aksControlPlaneFQDN
output aksClusterApiServerUri string = aks.outputs.aksApiServerUri
output acrName string = acr.outputs.registryName
output redisName string = redis.outputs.name
output redisPassword string = redis.outputs.password
