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

ruby -ryaml -rjson -e 'puts YAML.dump(JSON.parse(STDIN.read))' < import-spec.json > import-spec.yml

cat import-spec.yml

rm import-spec*
