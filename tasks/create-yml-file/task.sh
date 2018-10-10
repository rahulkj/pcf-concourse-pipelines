#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

echo "$PARAM_NAME" > work-folder/$OUTPUT_FILE_NAME
