#!/bin/bash

set -e
set -x

while getopts ":p:s:" arg; do
    case $arg in
        p) ResourcePrefix=$OPTARG;;
        s) ResourcePostfix=$OPTARG;;
    esac
done

usage() {
    script_name=`basename $0`
    echo "Please use ./$script_name -p resourcePrefix -s resourcePostfix"
}

if [ -z "$ResourcePrefix" ]; then
    usage
    exit 1
fi

if [ -z "$ResourcePostfix" ]; then
    usage
    exit 1
fi

resourcePrefix=$ResourcePrefix
resourcePostfix=$ResourcePostfix

pushd ../../src/DemoEdgeDevice/modules/DemoEdgeModule

az acr login --name "${resourcePrefix}acr${resourcePostfix}"
az acr build -t demoedgemodule:v1 -r "${resourcePrefix}acr${resourcePostfix}" --file Dockerfile.amd64 .

popd
