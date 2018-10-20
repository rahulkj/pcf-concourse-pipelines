#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

JSON=$(cat config/$EXTENSION_FILE)

CURL_CMD="$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -s"

EXISTING_EXTENSION=$($CURL_CMD -p /api/v0/staged/vm_extensions)

EXTENSION_FOUND=$(echo "$EXISTING_EXTENSION" | $JQ_CMD '.vm_extensions[] | select(.name | contains("router-extension"))')

if [ -z "$EXTENSION_FOUND" ]; then
  $CURL_CMD -p /api/v0/staged/vm_extensions -d "$JSON" -x POST
fi
