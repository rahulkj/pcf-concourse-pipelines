#!/bin/bash

chmod +x om-cli/om-linux

FILE_PATH=`find ./pivnet-metrics-product -name *.pivotal`

./om-cli/om-linux -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-product -p $FILE_PATH
