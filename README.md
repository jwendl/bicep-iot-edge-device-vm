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

