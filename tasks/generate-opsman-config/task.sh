#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64
GOVC_CMD=./govc/govc_linux_amd64

FILE_PATH=`find ./pivnet-product/ -name *.ova`

$GOVC_CMD import.spec $FILE_PATH > import-spec.json

yq e import-spec.json

rm import-spec*
