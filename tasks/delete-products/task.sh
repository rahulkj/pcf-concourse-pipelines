#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

$CMD -t https://$OPS_MGR_HOST -k --client-id $OPSMAN_CLIENT_ID --client-secret $OPSMAN_CLIENT_SECRET -u $OPS_MGR_USR -p $OPS_MGR_PWD delete-installation
