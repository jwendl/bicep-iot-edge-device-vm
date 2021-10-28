param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param userManagaedIdentityResourceId string
param iotEdgeDeviceName string
param version string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
    name: 'create-iot-edge-device'
    location: resourceGroupLocation
    kind: 'AzureCLI'
    identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${userManagaedIdentityResourceId}': {}
        }
    }
    properties: {
        forceUpdateTag: version
        azCliVersion: '2.27.2'
        timeout: 'PT30M'
        retentionInterval: 'P1D'
        scriptContent: concat('''
            az extension add --name azure-iot
            az iot hub device-identity create --resource-group ''', '${resourceGroup().name}',''' --device-id ''', '${iotEdgeDeviceName}', ''' --edge-enabled --hub-name ''', '${resourcePrefix}iot${resourcePostfix}', '''

            deviceConnectionString=$(az iot hub device-identity connection-string show --device-id ''', '${iotEdgeDeviceName}', ''' --hub-name ''', '${resourcePrefix}iot${resourcePostfix}', ''' --query connectionString --output tsv)
            jq -n --arg deviceConnectionString "$deviceConnectionString" -c '{ DeviceConnectionString: $deviceConnectionString }' > $AZ_SCRIPTS_OUTPUT_PATH
        ''')
    }
}

resource iotHubConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
    name: '${resourcePrefix}akv${resourcePostfix}/device-connection-string'
    properties: {
        value: deploymentScript.properties.outputs.deviceConnectionString
    }
}
