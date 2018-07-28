#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

PIVNET_CLI=`find ./pivnet-cli -name "*linux-amd64*"`
chmod +x $PIVNET_CLI

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

SC_VERSION=`cat ./pivnet-product/metadata.json | $JQ_CMD -r '.Dependencies[] | select(.Release.Product.Name | contains("Stemcells")) | .Release.Version' | head -1`

if [[ ! -z "$SC_VERSION" ]]; then
  STEMCELL_NAME=bosh-stemcell-$SC_VERSION-$IAAS_TYPE-ubuntu-trusty-go_agent.tgz

  DIAGNOSTIC_REPORT=$($OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -s -p /api/v0/diagnostic_report)
  STEMCELL_EXISTS=$(echo $DIAGNOSTIC_REPORT | $JQ_CMD -r --arg STEMCELL_NAME $STEMCELL_NAME '.stemcells | contains([$STEMCELL_NAME])')

  if $STEMCELL_EXISTS ; then
    echo "Stemcell already exists with Ops Manager, hence skipping this step"
  else
    echo "Downloading stemcell $SC_VERSION"
    $PIVNET_CLI login --api-token="$PIVNET_API_TOKEN"

    set +e
    RESPONSE=`$PIVNET_CLI releases -p stemcells | grep $SC_VERSION`
    set -e

    if [[ -z "$RESPONSE" ]]; then
      wget --show-progress https://s3.amazonaws.com/bosh-core-stemcells/vsphere/$STEMCELL_NAME
    else
      $PIVNET_CLI download-product-files -p stemcells -r $SC_VERSION -g "*$IAAS_TYPE*" --accept-eula
    fi

    SC_FILE_PATH=`find ./ -name *.tgz`

    $OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-stemcell -s $SC_FILE_PATH

    if [ ! -f "$SC_FILE_PATH" ]; then
        echo "Stemcell file not found!"
    else
      echo "Removing downloaded stemcell $SC_VERSION"
      rm $SC_FILE_PATH
    fi
  fi
else
  echo "Nothing to do here"
fi
