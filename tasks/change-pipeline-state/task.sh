#!/bin/sh

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

curl "$ATC_EXTERNAL_URL/api/v1/cli?arch=amd64&platform=linux" -k > fly

FLY_CLI=$(find . -name "fly")
chmod +x $FLY_CLI

$FLY_CLI -t cc login -c $ATC_EXTERNAL_URL -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWD -n $TEAM_NAME -k

$FLY_CLI -t cc $PIPELINE_STATE-pipeline -p $PIPELINE_NAME
