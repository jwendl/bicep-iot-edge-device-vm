param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param iotHubConsumerGroupName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
    name: '${resourcePrefix}estg${resourcePostfix}'
    location: resourceGroupLocation
    sku: {
        name: 'Standard_LRS'
    }
    kind: 'StorageV2'

    resource storageAccountBlobContainer 'blobServices' = {
        name: 'default'
        properties: {
            cors: {
                corsRules: [
                    {
                        allowedOrigins: [
                            'https://iothub.hosting.portal.azure.net'
                        ]
                        allowedMethods: [
                            'DELETE'
                            'GET'
                            'HEAD'
                            'MERGE'
                            'POST'
                            'OPTIONS'
                            'PUT'
                        ]
                        maxAgeInSeconds: 3000
                        exposedHeaders: [
                            '*'
                        ]
                        allowedHeaders: [
                            '*'
                        ]
                    }
                ]
            }
            deleteRetentionPolicy: {
                enabled: false
            }
        }

        resource storageAccountBlobContainerResource 'containers' = {
            name: 'events'
            properties: {
                publicAccess: 'None'
            }
        }
    }
}

resource iotHub 'Microsoft.Devices/IotHubs@2021-07-01' = {
    name: '${resourcePrefix}iot${resourcePostfix}'
    location: resourceGroupLocation
    sku: {
        capacity: 1
        name: 'S1'
    }
    properties: {
        authorizationPolicies: [
            {
                keyName: 'iothubowner'
                rights: 'RegistryWrite, ServiceConnect, DeviceConnect'
            }
            {
                keyName: 'service'
                rights: 'ServiceConnect'
            }
            {
                keyName: 'device'
                rights: 'DeviceConnect'
            }
            {
                keyName: 'registryRead'
                rights: 'RegistryRead'
            }
            {
                keyName: 'registryReadWrite'
                rights: 'RegistryWrite'
            }
            {
                keyName: 'deviceupdateservice'
                rights: 'RegistryRead, ServiceConnect, DeviceConnect'
            }
        ]
        cloudToDevice: {
            maxDeliveryCount: 10
            defaultTtlAsIso8601: 'PT1H'
            feedback: {
                lockDurationAsIso8601: 'PT1M'
                ttlAsIso8601: 'PT1H'
                maxDeliveryCount: 10
            }
        }
        enableFileUploadNotifications: false
        features: 'None'
        ipFilterRules: []
        messagingEndpoints: {
            fileNotifications: {
                lockDurationAsIso8601: 'PT1M'
                ttlAsIso8601: 'PT1H'
                maxDeliveryCount: 10
            }
        }
        routing: {
            endpoints: {
                eventHubs: []
                serviceBusQueues: []
                serviceBusTopics: []
                storageContainers: []
            }
            routes: [
                {
                    name: 'DeviceUpdate.DeviceTwinChanges'
                    source: 'TwinChangeEvents'
                    condition: '(opType = "updateTwin" OR opType = "replaceTwin") AND IS_DEFINED($body.tags.ADUGroup)'
                    endpointNames: [
                        'events'
                    ]
                    isEnabled: true
                }
                {
                    name: 'DeviceUpdate.DeviceLifecyle'
                    source: 'DeviceLifecycleEvents'
                    condition: 'opType = "deleteDeviceIdentity" OR opType = "deleteModuleIdentity"'
                    endpointNames: [
                        'events'
                    ]
                    isEnabled: true
                }
            ]
        }
    }
}

resource iotHubEventHubEndpointConsumerGroup 'Microsoft.Devices/IotHubs/eventHubEndpoints/ConsumerGroups@2021-07-01' = {
    name: '${iotHub.name}/events/${iotHubConsumerGroupName}'
    properties: {
        name: iotHubConsumerGroupName
    }
}

resource deviceAccount 'Microsoft.DeviceUpdate/accounts@2020-03-01-preview' = {
    name: '${resourcePrefix}ada${resourcePostfix}'
    location: resourceGroupLocation

    resource deviceAccountInstance 'instances' = {
        name: '${resourcePrefix}ada${resourcePostfix}'
        location: resourceGroupLocation
        properties: {
            iotHubs: [
                {
                    resourceId: iotHub.id
                    ioTHubConnectionString: 'HostName=${iotHub.properties.hostName};SharedAccessKeyName=${listKeys(iotHub.id, iotHub.apiVersion).value[0].keyName};SharedAccessKey=${listKeys(iotHub.id, iotHub.apiVersion).value[0].primaryKey}'
                    eventHubConnectionString: 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=${listKeys(iotHub.id, iotHub.apiVersion).value[0].keyName};SharedAccessKey=${listKeys(iotHub.id, iotHub.apiVersion).value[0].primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'
                }
            ]
        }
    }
}

resource akv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
    name: '${resourcePrefix}akv${resourcePostfix}'
    scope: resourceGroup(subscription().id, resourceGroup().name)
}

resource iotHubConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
    name: '${akv.name}/iot-hub-connection-string'
    properties: {
        value: 'HostName=${iotHub.properties.hostName};SharedAccessKeyName=${listKeys(iotHub.id, iotHub.apiVersion).value[0].keyName};SharedAccessKey=${listKeys(iotHub.id, iotHub.apiVersion).value[0].primaryKey}'
    }
}
