param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string

resource azureContainerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
    name: '${resourcePrefix}acr${resourcePostfix}'
    location: resourceGroupLocation
    sku: {
        name: 'Standard'
    }
    properties: {
        adminUserEnabled: false
    }
}
