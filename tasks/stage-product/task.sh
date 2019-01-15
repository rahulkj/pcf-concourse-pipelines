#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

if [[ (! -z "$DEPENDENCY_PRODUCT_TILES") && ("null" != "$DEPENDENCY_PRODUCT_TILES") ]]; then
  STAGED_PRODUCTS=$($CMD -e env/${OPSMAN_ENV_FILE_NAME} curl -s -p /api/v0/staged/products)

  for dependency in $(echo $DEPENDENCY_PRODUCT_TILES | sed "s/,/ /g")
  do
    DEPENDENCY_PRODUCT_FOUND=$(echo $STAGED_PRODUCTS | jq --arg product_name $dependency '.[] | select(.type | contains($product_name))')
    if [ -z "$DEPENDENCY_PRODUCT_FOUND" ]; then
      echo "Cannot find the dependency product tile $dependency, hence exitting"
      exit 1
    else
      echo "Found dependency product tile $dependency"
    fi
  done
fi

VERSION=`cat pivnet-product/metadata.json | jq '.Release.Version' | tr -d '"'`

RELEASE_NAME=`$CMD -e env/${OPSMAN_ENV_FILE_NAME} available-products | grep $PRODUCT_NAME | grep $VERSION`

PRODUCT_VERSION=`echo $RELEASE_NAME | cut -d"|" -f3 | tr -d " "`

$CMD -e env/${OPSMAN_ENV_FILE_NAME} stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION
