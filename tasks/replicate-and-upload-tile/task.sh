#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x replicator/replicator-linux
CMD=./replicator/replicator-linux

INPUT_FILE_PATH=`find ./pivnet-product -name "*.pivotal"`
FILE_NAME=`echo $INPUT_FILE_PATH | cut -d '/' -f3`
OUTPUT_FILE_PATH=replicator-tile/$FILE_NAME

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

if [[ ! -z "$REPLICATOR_NAME" ]]; then
  echo "Replicating the tile and adding " $REPLICATOR_NAME
  $CMD -name $REPLICATOR_NAME -path $INPUT_FILE_PATH -output $OUTPUT_FILE_PATH
  $OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-product -p $OUTPUT_FILE_PATH
else
  echo "Uploading tile without any replication"
  FILE_PATH=`find ./pivnet-product -name *.pivotal`
  $OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-product -p $FILE_PATH
fi

rm -rf $OUTPUT_FILE_PATH
