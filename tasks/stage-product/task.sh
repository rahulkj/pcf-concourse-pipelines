#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

if [[ (! -z "$DEPENDENCY_PRODUCT_TILES") && ("null" != "$DEPENDENCY_PRODUCT_TILES") ]]; then
  STAGED_PRODUCTS=$($CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -s -p /api/v0/staged/products)

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

RELEASE_NAME=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep $PRODUCT_IDENTIFIER | grep $VERSION`

PRODUCT_NAME=`echo $RELEASE_NAME | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $RELEASE_NAME | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION
