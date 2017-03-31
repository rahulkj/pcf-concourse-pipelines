#!/bin/bash -eu

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

PRODUCT_VERSION=`echo pivnet-product/metadata.json | jq '.ProductFiles | .[] | select ( .File | contains("PCF Elastic Runtime")) | .FileVersion' | tr -d '"'`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_IDENTIFIER -v $PRODUCT_VERSION
