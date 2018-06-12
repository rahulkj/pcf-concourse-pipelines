#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64
GOVC_CMD=./govc/govc_linux_amd64

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

FILE_PATH=`find ./pivnet-product/ -name *.ova`

echo "$OPS_MANAGER_SETTINGS" > ops_manager_settings.yml

ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < ops_manager_settings.yml > options.json

$GOVC_CMD import.ova -options=options.json $FILE_PATH

rm *.json
