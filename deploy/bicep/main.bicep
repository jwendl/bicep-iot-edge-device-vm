param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param currentUserObjectId string
param version string

resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
    name: '${resourcePrefix}umi${resourcePostfix}'
    location: resourceGroupLocation
}

resource umiTemplateRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
    name: guid(umi.id)
    properties: {
        principalId: umi.properties.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    }
    dependsOn: [
        umi
    ]
}

module keyVault 'modules/key-vault.bicep' = {
    name: 'key-vault-${version}'
    params: {
        resourcePrefix: resourcePrefix
        resourcePostfix: resourcePostfix
        resourceGroupLocation: resourceGroupLocation
        currentUserObjectId: currentUserObjectId
        userManagedIdentityObjectId: umi.properties.principalId
    }
}

resource armTemplateRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
    name: guid(resourceGroup().id)
    properties: {
        principalId: '8b967430-badb-45ba-8d11-bca192994047'
        roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    }
}

module sshKeys 'modules/ssh-keys.bicep' = {
    name: 'ssh-keys-${version}'
    params: {
        resourcePrefix: resourcePrefix
        resourcePostfix: resourcePostfix
        resourceGroupLocation: resourceGroupLocation
        userManagaedIdentityResourceId: umi.id
        version: version
    }
    dependsOn: [
        keyVault
    ]
}

module containerRegistry 'modules/container-registry.bicep' = {
    name: 'container-registry-${version}'
    params: {
        resourcePrefix: resourcePrefix
        resourcePostfix: resourcePostfix
        resourceGroupLocation: resourceGroupLocation
    }
}

module iotHub 'modules/iot-hub.bicep' = {
    name: 'iot-hub-${version}'
    params: {
        resourcePrefix: resourcePrefix
        resourcePostfix: resourcePostfix
        resourceGroupLocation: resourceGroupLocation
        iotHubConsumerGroupName: 'events'
    }
    dependsOn: [
        keyVault
    ]
}

module iotEdgeDevice 'modules/iot-edge-device.bicep' = {
    name: 'iot-edge-device-${version}'
    params: {
        resourcePrefix: resourcePrefix
        resourcePostfix: resourcePostfix
        resourceGroupLocation: resourceGroupLocation
        userManagaedIdentityResourceId: umi.id
        iotEdgeDeviceName: 'vm-edge-device'
        version: version
    }
    dependsOn: [
        keyVault
    ]
}

module iotEdge 'modules/iot-edge.bicep' = {
    name: 'iot-edge-${version}'
    params: {
        resourcePrefix: resourcePrefix
        resourcePostfix: resourcePostfix
        resourceGroupLocation: resourceGroupLocation
        sshPublicKey: sshKeys.outputs.publicKey
        userManagedIdentityAppId: umi.properties.clientId
        userManagaedIdentityResourceId: umi.id
        version: version
    }
    dependsOn: [
        keyVault
        iotEdgeDevice
        iotHub
    ]
}
