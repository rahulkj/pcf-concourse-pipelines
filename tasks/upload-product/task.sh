#!/bin/bash -ex

if [[ ! -z "$NO_PROXY" ]]; then
  echo "$OPS_MGR_IP $OPS_MGR_HOST" >> /etc/hosts
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

FILE_PATH=`find ./pivnet-product -name *.pivotal`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-product -p $FILE_PATH
