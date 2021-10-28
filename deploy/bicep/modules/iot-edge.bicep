param resourcePrefix string
param resourcePostfix string
param resourceGroupLocation string
param version string
param adminUsername string = 'adminuser'
param userManagedIdentityAppId string
param userManagaedIdentityResourceId string

@secure()
param sshPublicKey string

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
    name: '${resourcePrefix}abas${resourcePostfix}'
    location: resourceGroupLocation
    properties: {
        ipConfigurations: [
            {
                name: 'ipconfig'
                properties: {
                    subnet: {
                        id: virtualNetwork.properties.subnets[1].id
                    }
                    publicIPAddress: {
                        id: publicIpAddress.id
                    }
                }
            }
        ]
    }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
    name: '${resourcePrefix}nsg${resourcePostfix}'
    location: resourceGroupLocation
    properties: {
        securityRules: [
            {
                name: 'outbound-tcp'
                properties: {
                    priority: 1200
                    protocol: 'Tcp'
                    access: 'Allow'
                    direction: 'Outbound'
                    sourceAddressPrefix: '*'
                    sourcePortRange: '*'
                    destinationAddressPrefix: '*'
                    destinationPortRange: '*'
                }
            }
            {
                name: 'outbound-udp'
                properties: {
                    priority: 1300
                    protocol: 'Udp'
                    access: 'Allow'
                    direction: 'Outbound'
                    sourceAddressPrefix: '*'
                    sourcePortRange: '*'
                    destinationAddressPrefix: '*'
                    destinationPortRange: '*'
                }
            }
        ]
    }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
    name: '${resourcePrefix}pip${resourcePostfix}'
    location: resourceGroupLocation
    sku: {
        name: 'Standard'
    }
    properties: {
        publicIPAllocationMethod: 'Static'
        publicIPAddressVersion: 'IPv4'
        dnsSettings: {
            domainNameLabel: '${resourcePrefix}avm${resourcePostfix}'
        }
    }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-03-01' = {
    name: '${resourcePrefix}vnet${resourcePostfix}'
    location: resourceGroupLocation
    properties: {
        networkSecurityGroup: {
            id: networkSecurityGroup.id
        }
        ipConfigurations: [
            {
                name: '${resourcePrefix}nic${resourcePostfix}'
                properties: {
                    subnet: {
                        id: virtualNetwork.properties.subnets[0].id
                    }
                }
            }
        ]
    }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
    name: '${resourcePrefix}nic${resourcePostfix}'
    location: resourceGroupLocation
    properties: {
        addressSpace: {
            addressPrefixes: [
                '10.1.0.0/16'
            ]
        }
        subnets: [
            {
                name: '${resourcePrefix}vsub${resourcePostfix}'
                properties: {
                    addressPrefix: '10.1.5.0/24'
                }
            }
            {
                name: 'AzureBastionSubnet'
                properties: {
                    addressPrefix: '10.1.6.0/24'
                }
            }
        ]
    }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
    name: '${resourcePrefix}avm${resourcePostfix}'
    location: resourceGroupLocation
    identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${userManagaedIdentityResourceId}': {}
        }
    }
    properties: {
        hardwareProfile: {
            vmSize: 'Standard_D8s_v3'
        }
        storageProfile: {
            osDisk: {
                createOption: 'FromImage'
                managedDisk: {
                    storageAccountType: 'Premium_LRS'
                }
            }
            imageReference: {
                publisher: 'Canonical'
                offer: '0001-com-ubuntu-server-focal'
                sku: '20_04-lts-gen2'
                version: 'latest'
            }
        }
        networkProfile: {
            networkInterfaces: [
                {
                    id: networkInterface.id
                }
            ]
        }
        osProfile: {
            computerName: '${resourcePrefix}avm${resourcePostfix}'
            adminUsername: adminUsername
            linuxConfiguration: {
                disablePasswordAuthentication: true
                ssh: {
                    publicKeys: [
                        {
                            path: '/home/${adminUsername}/.ssh/authorized_keys'
                            keyData: sshPublicKey
                        }
                    ]
                }
            }
        }
    }
    resource vmExtension 'extensions' = {
        name: '${resourcePrefix}vmext${resourcePostfix}'
        location: resourceGroupLocation
        properties: {
            publisher: 'Microsoft.Azure.Extensions'
            type: 'CustomScript'
            typeHandlerVersion: '2.0'
            autoUpgradeMinorVersion: true
            forceUpdateTag: version
            protectedSettings: {
                script: base64(concat('''
                    export DEBIAN_FRONTEND="noninteractive"
                    
                    sudo apt-get update
                    sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg --yes
                    
                    curl -sL https://packages.microsoft.com/keys/microsoft.asc | --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
                    AZ_REPO=$(lsb_release -cs)
                    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
                    sudo apt-get update
                    sudo apt-get install azure-cli --yes

                    az login --identity --username ''', '${userManagedIdentityAppId}', ''' --allow-no-subscriptions
                    curl -s https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
                    sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/

                    curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
                    sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
                    sudo apt-get update
                    sudo apt-get install moby-engine --yes

                    curl -sSL https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh -o check-config.sh
                    chmod +x check-config.sh
                    ./check-config.sh

                    sudo apt-get update
                    sudo apt-get install aziot-edge --yes

                    deviceConnectionString=$(az keyvault secret show --vault-name ''', '${resourcePrefix}akv${resourcePostfix}', ''' --name device-connection-string --query value --output tsv)
                    sudo iotedge config mp --connection-string "${deviceConnectionString}" --force
                    sudo iotedge config apply -c '/etc/aziot/config.toml'
                '''))
            }
        }
    }
}
