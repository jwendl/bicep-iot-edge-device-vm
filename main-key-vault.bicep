param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param currentUserObjectId string
param version string = base64ToString(base64(utcNow()))

resource akv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: '${resourcePrefix}akv${resourcePostfix}'
  scope: resourceGroup()
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'key-vault-${version}'
  params: {
      resourcePrefix: resourcePrefix
      resourcePostfix: resourcePostfix
      resourceGroupLocation: resourceGroupLocation
      currentUserObjectId: currentUserObjectId
  }
}
