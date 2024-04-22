param location string
param suffix string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param name string
param capacity int = 1

var redisName = 'redis-${suffix}'

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
    publicNetworkAccess: 'Enabled'
    updateChannel: 'Stable'
  }
}

output password string = redis.listKeys(redis.apiVersion).primaryKey
output name string = redis.name
