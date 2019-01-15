#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

SC_FILE_PATH=`find stemcells/ -name *.tgz`

if [ ! -f "$SC_FILE_PATH" ]; then
    echo "Stemcell file not found!"
else
  $OM_CMD -e env/${OPSMAN_ENV_FILE_NAME} upload-stemcell -s $SC_FILE_PATH
fi
