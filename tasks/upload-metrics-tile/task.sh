#!/bin/bash

chmod +x tool-om/om-linux

FILE_PATH=`find ./pivnet-metrics-product -name *.pivotal`

./tool-om/om-linux -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-product -p $FILE_PATH
