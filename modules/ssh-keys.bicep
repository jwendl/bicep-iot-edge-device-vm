param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param version string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
    name: 'create-keys-save-key-vault'
    location: resourceGroupLocation
    kind: 'AzureCLI'
    properties: {
        forceUpdateTag: version
        azCliVersion: '2.27.2'
        retentionInterval: 'P1D'
        scriptContent: concat('''
            if az keyvault secret show --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''" --name "ssh-key-public" --output none; then
            az keyvault secret show --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''" --name "ssh-key-private" --query value --output tsv > ./key
            az keyvault secret show --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''" --name "ssh-key-public" --query value --output tsv > ./key.pub
            else
            keyFileName=./key
            ssh-keygen -q -m PEM -t rsa -b 4096 -N '' -f ./key
            az keyvault secret set --name "ssh-key-private" --value "$(cat ./key)" --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''"
            az keyvault secret set --name "ssh-key-public" --value "$(cat ./key.pub)" --vault-name "''', '${resourcePrefix}akv${resourcePostfix}', '''"
            sshPublicKey=$(cat ./key.pub)
            rm ./key
            rm ./key.pub
            fi
        ''')
    }
}
