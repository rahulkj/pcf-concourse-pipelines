#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

VERSION=`cat pivnet-product/metadata.json | jq -r '.Release.Version'`

RELEASE_NAME=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -s -p /api/v0/available_products | jq --arg product_name $PRODUCT_IDENTIFIER '.[] | select(.name == $product_name)'`

PRODUCT_NAME=`echo "$RELEASE_NAME" | jq -r '.name'`
PRODUCT_VERSION=`echo $RELEASE_NAME | jq -r '.product_version'`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k unstage-product -p $PRODUCT_NAME
