#!/bin/bash -e

BUILDPACK_FILE_PATH='ls pivnet-product | grep *.tgz'

tar -xf cf-cli/*.tgz cf
chmod +x cf

CMD=./cf

$CMD api --skip-ssl-validation $CF_API_ENDPOINT

$CMD login -u $CF_USER -p $CF_PASSWORD -o $ORG -s $SPACE

EXISTS=`$CMD curl /v2/buildpacks | jq --arg name $BUILDPACK_NAME '.resources | .[] | select (.entity.name | contains($name))'`

if [[ -z "$EXISTS" ]]; then
  echo "Creating the buildpack $BUILDPACK_NAME and setting it at position $BUILDPACK_POSITION..."
  cf create-buildpack $BUILDPACK_NAME -p $BUILDPACK_FILE_PATH --$IS_ENABLE --i $BUILDPACK_POSITION
else
  if [[ -z "$BUILDPACK_POSITION" ]]; then
    BP_POSITION=`echo $EXISTS | jq '.entity.position' | tr -d '"'`
  else
    BP_POSITION=$BUILDPACK_POSITION
  fi
  echo "Updating the buildpack $BUILDPACK_NAME and setting it at position $BP_POSITION..."
  cf update-buildpack $BUILDPACK_NAME -p $BUILDPACK_FILE_PATH --$IS_ENABLE --i $BP_POSITION
fi
