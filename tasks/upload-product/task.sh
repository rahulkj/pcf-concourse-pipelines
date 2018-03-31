#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

FILE_PATH=`find ./pivnet-product -name *.pivotal`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-product -p $FILE_PATH
