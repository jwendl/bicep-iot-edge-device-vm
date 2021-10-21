param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param version string = base64ToString(base64(utcNow()))

resource armTemplateRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
    name: guid(resourceGroup().id)
    properties: {
        principalId: '8b967430-badb-45ba-8d11-bca192994047'
        roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
        principalType: 'User'
    }
}

module sshKeys 'modules/ssh-keys.bicep' = {
    name: 'ssh-keys-${version}'
    params: {
        resourcePrefix: resourcePrefix
        resourcePostfix: resourcePostfix
        resourceGroupLocation: resourceGroupLocation
        version: version
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
}
