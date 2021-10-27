param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param userManagaedIdentityResourceId string
param version string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
    name: 'create-keys-save-key-vault'
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
            if az keyvault secret show --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''" --name "ssh-public-key" --output none
            then
                az keyvault secret show --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''" --name "ssh-public-key" --query value --output tsv > ./key.pub
            else
                ssh-keygen -q -m PEM -t rsa -b 4096 -N '' -f ./key
                az keyvault secret set --name "ssh-private-key" --value "$(cat ./key)" --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''"
                az keyvault secret set --name "ssh-public-key" --value "$(cat ./key.pub)" --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''"
                rm ./key
                rm ./key.pub
            fi
            sshPublicKey=$(cat ./key.pub)
            jq -n --arg sshPublicKey "$sshPublicKey" -c '{ SshPublicKey: $sshPublicKey }' > $AZ_SCRIPTS_OUTPUT_PATH
        ''')
    }
}

output publicKey string = deploymentScript.properties.outputs.SshPublicKey
