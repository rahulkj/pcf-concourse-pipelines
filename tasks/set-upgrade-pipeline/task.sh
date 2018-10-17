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
  -v product_slug="$PRODUCT_SLUG" \
  -v product_version="$PRODUCT_VERSION" \
  -v product_name="$PRODUCT_NAME" \
  -v product_glob="$PRODUCT_GLOB" \
  -v dependency_product_tiles="$DEPENDENCY_PRODUCT_TILES" \
  -v apply_changes_config="$APPLY_CHANGES_CONFIG"
$FLY_CLI -t cc unpause-pipeline -p $UPGRADE_PIPELINE_NAME
