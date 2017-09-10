#!/bin/sh -ex

 curl "$ATC_EXTERNAL_URL/api/v1/cli?arch=amd64&platform=linux" > fly

FLY_CLI=$(find . -name "fly")
chmod +x $FLY_CLI

$FLY_CLI -t cc login -c $ATC_EXTERNAL_URL -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWD -n $TEAM_NAME

$FLY_CLI -t cc $PIPELINE_STATE-pipeline -p $PIPELINE_NAME
