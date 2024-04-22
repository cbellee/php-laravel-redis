param location string
param suffix string 
var redisName = 'redis-${suffix}'

resource redis 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisName
  location: location
  properties: {
    sku: {
      capacity: 1
      family: 'P'
      name: 'Premium'
    }
    enableNonSslPort: true
    publicNetworkAccess: 'Enabled'
    updateChannel: 'Stable'
  }
}

output password string = redis.listKeys(redis.apiVersion).primaryKey
output name string = redis.name
