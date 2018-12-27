#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

FILE_PATH=`find ./product -name *.pivotal`

$CMD -k upload-product -p $FILE_PATH
