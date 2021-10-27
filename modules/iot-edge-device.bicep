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
            az iot hub device-identity create --device-id ''', '${iotEdgeDeviceName}', ''' --edge-enabled --hub-name ''', '${resourcePrefix}iot${resourcePostfix}', '''
        ''')
    }
}
