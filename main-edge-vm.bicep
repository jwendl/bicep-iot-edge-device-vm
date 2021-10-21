param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param version string = base64ToString(base64(utcNow()))

resource akv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: '${resourcePrefix}akv${resourcePostfix}'
  scope: resourceGroup()
}

module iotEdge 'modules/iot-edge.bicep' = {
  name: 'iot-edge-${version}'
  params: {
      resourcePrefix: resourcePrefix
      resourcePostfix: resourcePostfix
      resourceGroupLocation: resourceGroupLocation
      iotHubConnectionString: akv.getSecret('iot-hub-connection-string')
      sshPublicKey: akv.getSecret('ssh-public-key')
      version: version
  }
}
