#!/bin/bash -e

if [[ ! -z "$NO_PROXY" ]]; then
  echo "$OM_IP $OPS_MGR_HOST" >> /etc/hosts
fi

PIVNET_CLI=`find ./pivnet-cli -name "*linux-amd64*"`
chmod +x $PIVNET_CLI

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

STEMCELL_VERSION=`cat ./pivnet-product/metadata.json | jq '.Dependencies[] | select(.Release.Product.Name | contains("Stemcells")) | .Release.Version'`

echo "Downloading stemcell $STEMCELL_VERSION"
$PIVNET_CLI login --api-token="$PIVNET_API_TOKEN"

set +e
RESPONSE=`$PIVNET_CLI releases -p stemcells | grep $STEMCELL_VERSION`
set -e

if [[ -z "$RESPONSE" ]]; then
  wget --show-progress https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-$STEMCELL_VERSION-$IAAS_TYPE-esxi-ubuntu-trusty-go_agent.tgz
else
  $PIVNET_CLI download-product-files -p stemcells -r $STEMCELL_VERSION -g "*$IAAS_TYPE*" --accept-eula
fi

SC_FILE_PATH=`find ./ -name *.tgz`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-stemcell -s $SC_FILE_PATH

if [ ! -f "$SC_FILE_PATH" ]; then
    echo "Stemcell file not found!"
else
  echo "Removing downloaded stemcell $STEMCELL_VERSION"
  rm $SC_FILE_PATH
fi
