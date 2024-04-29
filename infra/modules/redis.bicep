param location string
param suffix string
param vnetName string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param name string
param capacity int = 1

var redisName = 'redis-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
}

resource redis 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisName
  location: location
  properties: {
    sku: {
      capacity: capacity
      family: name == 'Premium' ? 'P' : 'C'
      name: name
    }
    enableNonSslPort: true
    publicNetworkAccess: 'Disabled'
    updateChannel: 'Stable'
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.redis.cache.windows.net'
  location: 'global'
  properties: {}
}

resource private_dns_zone_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: private_dns_zone
  name: 'redis-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource redis_pe 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'redis-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'redis-pe-cxn'
        properties: {
          privateLinkServiceId: redis.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: vnet.properties.subnets[2].id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource redis_pe_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: redis_pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-redis-cache-windows-net'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}

output password string = redis.listKeys(redis.apiVersion).primaryKey
output name string = redis.name
