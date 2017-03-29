#!/bin/bash -eu

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

RELEASE_NAME=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep $PRODUCT_IDENTIFIER`

PRODUCT_NAME=`echo $RELEASE_NAME | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $RELEASE_NAME | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION
