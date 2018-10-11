#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

cp input-folder/* output-folder/
echo "$PARAM_NAME" > output-folder/$OUTPUT_FILE_NAME
