#!/bin/sh

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

curl -k "$CONCOURSE_URL/api/v1/cli?arch=amd64&platform=linux" > fly

FLY_CLI=$(find . -name "fly")
chmod +x $FLY_CLI

$FLY_CLI -t cc login -k -c $CONCOURSE_URL -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWD -n $BUILD_TEAM_NAME
$FLY_CLI -t cc set-pipeline -n -p $UPGRADE_PIPELINE_NAME -c pipelines-repo/pipelines/upgrade-tile/pipeline.yml \
  -l pipelines-repo/pipelines/upgrade-tile/params.yml \
  -v product_name="$PRODUCT_NAME" \
  -v product_version="$PRODUCT_VERSION" \
  -v product_identifier="$PRODUCT_IDENTIFIER" \
  -v product_glob="*.pivotal"
$FLY_CLI -t cc unpause-pipeline -p $UPGRADE_PIPELINE_NAME
$FLY_CLI -t cc pause-pipeline -p $BUILD_PIPELINE_NAME
