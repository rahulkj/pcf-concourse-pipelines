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
else
  echo "Uploading tile without any replication"
  cp $INPUT_FILE_PATH $OUTPUT_FILE_PATH
fi

$OM_CMD -e env/${OPSMAN_ENV_FILE_NAME} upload-product -p $OUTPUT_FILE_PATH
rm -rf $OUTPUT_FILE_PATH
