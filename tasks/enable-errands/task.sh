#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

if [[ ! -z "$ERRANDS" ]]; then
  echo "Errands to enable are " $ERRANDS
  for i in $(echo $ERRANDS | sed "s/,/ /g")
  do
    echo "$i"
    set +e
    ERRAND_EXISTS=`$OM_CMD -k errands -f json \
      -p $PRODUCT_NAME | jq -r --arg errand $i '.[] | select(.name==$errand) | .name'`

    set -e
    echo $ERRAND_EXISTS

    if [[ ! -z "$ERRAND_EXISTS" ]]; then
      echo $i " errand found... and enabling..."
      $OM_CMD -k set-errand-state -p $PRODUCT_NAME -e $i --post-deploy-state enabled
    else
      echo $i " errand not found... skipping..."
    fi
  done
else
  echo "No errands to enable"
fi
