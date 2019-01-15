#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

STAGED_PRODUCTS=$($CMD -e env/${OPSMAN_ENV_FILE_NAME} curl -p /api/v0/staged/products -s)
PRODUCT_GUID=$(echo $STAGED_PRODUCTS | jq --arg PRODUCT_NAME $PRODUCT_NAME '.[] | select(.type | contains ($PRODUCT_NAME))' | jq '.guid' | tr -d '"')

if [[ -z "$PRODUCT_GUID" ]]; then
  echo "Product with identifier $PRODUCT_NAME not found!"
  exit 1
fi

PENDING_CHANGES=$($CMD -e env/${OPSMAN_ENV_FILE_NAME} curl -p /api/v0/staged/pending_changes -s)
PENDING_CHANGES_LENGTH=$(echo "$PENDING_CHANGES" | jq '.product_changes | length')

if [[ "$PENDING_CHANGES_LENGTH" -eq "0" ]]; then
  exit 0
fi

while [[ "$PENDING_CHANGES_LENGTH" -ne "1" ]]; do
  PENDING_CHANGES=$($CMD -e env/${OPSMAN_ENV_FILE_NAME} curl -p /api/v0/staged/pending_changes -s)
  PENDING_CHANGES_LENGTH=$(echo "$PENDING_CHANGES" | jq '.product_changes | length')
  printf "."
  sleep 5
done

if [[ $(echo $PENDING_CHANGES | jq --arg guid $PRODUCT_GUID '.product_changes | .[].guid | contains ($guid)') == "true" ]]; then
  echo "queue is clean and this pipeline is good to call apply changes"
else
  echo "something is wrong.. :( ... cancel this build and try again later"
  exit 1
fi
