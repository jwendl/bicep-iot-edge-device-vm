param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param currentUserObjectId string

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
    name: '${resourcePrefix}akv${resourcePostfix}'
    location: resourceGroupLocation
    properties: {
        sku: {
            name: 'standard'
            family: 'A'
        }
        accessPolicies: [
            {
                tenantId: subscription().tenantId
                objectId: currentUserObjectId

                permissions: {
                    secrets: [
                        'list'
                        'get'
                        'set'
                    ]
                }
            }
            {
                tenantId: subscription().tenantId
                objectId: 'f248a218-1ef9-47bf-9928-ae47093fd442'

                permissions: {
                    secrets: [
                        'get'
                        'set'
                    ]
                }
            }
        ]
        enabledForDeployment: true
        enabledForTemplateDeployment: true
        enableSoftDelete: false
        tenantId: subscription().tenantId
    }
}

output keyVaultName string = keyVault.name
