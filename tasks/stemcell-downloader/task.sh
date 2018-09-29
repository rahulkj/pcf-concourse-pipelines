#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

PIVNET_CLI=`find ./pivnet-cli -name "*linux-amd64*"`
chmod +x $PIVNET_CLI

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

SC_DETAILS=`cat ./pivnet-product/metadata.json | $JQ_CMD -r '[.Dependencies[] | select(.Release.Product.Name | contains("Stemcells"))][0]'`

SC_VERSION=$(echo "$SC_DETAILS" | $JQ_CMD -r '.Release.Version')
PRODUCT_SLUG=$(echo "$SC_DETAILS" | $JQ_CMD -r '.Release.Product.Slug')

echo "Downloading stemcell $SC_VERSION"
$PIVNET_CLI login --api-token="$PIVNET_API_TOKEN"

set +e
RESPONSE=`$PIVNET_CLI releases -p $PRODUCT_SLUG | grep $SC_VERSION`
set -e

if [[ -z "$RESPONSE" ]]; then
  STEMCELL_NAME=bosh-stemcell-$SC_VERSION-$IAAS_TYPE-ubuntu-$STEMCELL_TYPE-go_agent.tgz
  wget --show-progress https://s3.amazonaws.com/bosh-core-stemcells/$IAAS/$STEMCELL_NAME
else
  $PIVNET_CLI download-product-files -p $PRODUCT_SLUG -r $SC_VERSION -g "*$IAAS_TYPE*" --accept-eula
fi

SC_FILE_PATH=`find ./ -name *.tgz`

mv $SC_FILE_PATH stemcells/
