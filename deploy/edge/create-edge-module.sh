#!/bin/bash

set -e
set -x

while getopts ":p:s:d:" arg; do
    case $arg in
        p) ResourcePrefix=$OPTARG;;
        s) ResourcePostfix=$OPTARG;;
        d) DeviceId=$OPTARG;;
    esac
done

usage() {
    script_name=`basename $0`
    echo "Please use ./$script_name -p resourcePrefix -s resourcePostfix -d deviceId"
}

if [ -z "$ResourcePrefix" ]; then
    usage
    exit 1
fi

if [ -z "$ResourcePostfix" ]; then
    usage
    exit 1
fi

if [ -z "$DeviceId" ]; then
    usage
    exit 1
fi

resourcePrefix=$ResourcePrefix
resourcePostfix=$ResourcePostfix
deviceId=$DeviceId

az iot edge set-modules --device-id $deviceId --hub-name "${resourcePrefix}iot${resourcePostfix}" --content ../../src/DemoEdgeDevice/deployment.json
