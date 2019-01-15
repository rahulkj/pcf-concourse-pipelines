#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

VERSION=`cat pivnet-product/metadata.json | jq -r '.Release.Version'`

RELEASE_NAME=`$CMD -e env/${OPSMAN_ENV_FILE_NAME} curl -s -p /api/v0/available_products | jq --arg product_name $PRODUCT_NAME '.[] | select(.name == $product_name)'`

PRODUCT_NAME=`echo "$RELEASE_NAME" | jq -r '.name'`
PRODUCT_VERSION=`echo $RELEASE_NAME | jq -r '.product_version'`

$CMD -e env/${OPSMAN_ENV_FILE_NAME} unstage-product -p $PRODUCT_NAME
