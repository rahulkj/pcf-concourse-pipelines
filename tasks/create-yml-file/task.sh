#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

echo "$PARAM_NAME" > output-folder/$OUTPUT_FILE_NAME
