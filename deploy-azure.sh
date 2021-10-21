#!/bin/bash

set -e
set -x

while getopts ":p:s:g:l:" arg; do
    case $arg in
        p) ResourcePrefix=$OPTARG;;
        s) ResourcePostfix=$OPTARG;;
        g) ResourceGroupName=$OPTARG;;
        l) ResourceGroupLocation=$OPTARG;;
    esac
done

usage() {
    script_name=`basename $0`
    echo "Please use ./$script_name -p resourcePrefix -s resourcePostfix -g resourceGroupName -l resourceGroupLocation"
}

if [ -z "$ResourcePrefix" ]; then
    usage
    exit 1
fi

if [ -z "$ResourcePostfix" ]; then
    usage
    exit 1
fi

if [ -z "$ResourceGroupName" ]; then
    usage
    exit 1
fi

if [ -z "$ResourceGroupLocation" ]; then
    usage
    exit 1
fi

resourcePrefix=$ResourcePrefix
resourcePostfix=$ResourcePostfix
resourceGroupName=$ResourceGroupName
resourceGroupLocation=$ResourceGroupLocation
currentUserObjectId=$(az ad signed-in-user show --query objectId --output tsv)

az group create --name $resourceGroupName --location $resourceGroupLocation
az deployment group create --template-file ./main-key-vault.bicep --resource-group $resourceGroupName --parameters "resourcePrefix=${resourcePrefix}" --parameters "resourcePostfix=${resourcePostfix}" --parameters "resourceGroupLocation=${resourceGroupLocation}"  --parameters "currentUserObjectId=${currentUserObjectId}"
az deployment group create --template-file ./main-requirements.bicep --resource-group $resourceGroupName --parameters "resourcePrefix=${resourcePrefix}" --parameters "resourcePostfix=${resourcePostfix}" --parameters "resourceGroupLocation=${resourceGroupLocation}"
az deployment group create --template-file ./main-edge-vm.bicep --resource-group $resourceGroupName --parameters "resourcePrefix=${resourcePrefix}" --parameters "resourcePostfix=${resourcePostfix}" --parameters "resourceGroupLocation=${resourceGroupLocation}"
