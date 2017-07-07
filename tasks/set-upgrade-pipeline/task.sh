#!/bin/sh -ex

 curl "http://$ATC_EXTERNAL_URL/api/v1/cli?arch=amd64&platform=linux" > fly

FLY_CLI=$(find . -name "fly")
chmod +x $FLY_CLI

$FLY_CLI -t cc login -c $ATC_EXTERNAL_URL -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWD -n $BUILD_TEAM_NAME
$FLY_CLI -t cc set-pipeline -n -p $UPGRADE_PIPELINE_NAME -c concourse-vsphere/pipelines/upgrade-tile/pipeline.yml
$FLY_CLI -t cc unpause-pipeline -p $UPGRADE_PIPELINE_NAME
$FLY_CLI -t cc pause-pipeline -p $BUILD_PIPELINE_NAME
