# An Example of Creating an IoT Edge VM with Bastion using Bicep

## How to Run

``` bash
./deploy-azure.sh -p {resource-prefix} -s {resource-postfix} -g {resource-group-name} -l {resource-group-location}
```

> The values for the above command can be found in the table below.

| Variable                | Description                                                    | Example   |
| ----------------------- | -------------------------------------------------------------- | --------- |
| resource-prefix         | The prefix for your Azure resources                            | jw        |
| resource-postfix        | The postfix for your Azure resources                           | dev       |
| resource-group-name     | The resource group you want to store your Azure resources      | TestGroup |
| resource-group-location | The location that you want to put all the Azure resources into | westus2   |

## Create Edge Device Manually

``` bash
az extension add --name azure-iot
az iot hub device-identity create --resource-group IoTEdge --device-id vm-edge-device --edge-enabled --hub-name jwiotdev
deviceConnectionString=$(az iot hub device-identity connection-string show --device-id vm-edge-device --hub-name jwiotdev --query connectionString --output tsv)
az keyvault secret set --vault-name jwakvdev --name device-connection-string --value "${deviceConnectionString}"
```

> Above script run on local machine

## Configure Edge Device Manually

``` bash
deviceConnectionString=$(az keyvault secret show --vault-name jwakvdev --name device-connection-string --query value --output tsv)
sudo iotedge config mp --connection-string "${deviceConnectionString}" --force
sudo iotedge config apply -c '/etc/aziot/config.toml'
```

## Troubleshooting

### IoT Edge edgeAgent complains about permissions issues in /var/run

Just run the following script and then re apply the steps above.

``` bash
sudo docker rm -f $(sudo docker ps -aq -f "label=net.azure-devices.edge.owner=Microsoft.Azure.Devices.Edge.Agent") && sudo systemctl stop iotedge
```
