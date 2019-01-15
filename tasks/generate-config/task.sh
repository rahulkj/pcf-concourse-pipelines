#!/bin/bash -e

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

chmod +x ./tile-config-convertor/tile-config-convertor_linux_amd64
TCC_CMD=./tile-config-convertor/tile-config-convertor_linux_amd64

function cleanAndEchoProperties {
  INPUT=$1
  OUTPUT=$2

  echo "$PROPERTIES" >> $INPUT
  $TCC_CMD -g properties -i $INPUT -o $OUTPUT

  sed -i -e 's/^/  /' $OUTPUT
  cat $OUTPUT
  echo ""
}

function cleanAndEchoResources() {
  INPUT=$1
  OUTPUT=$2

  echo "$RESOURCES" >> $INPUT
  $TCC_CMD -g resources -i $INPUT -o $OUTPUT

  sed -i -e 's/^/  /' $OUTPUT
  cat $OUTPUT
  echo ""
}

function cleanAndEchoErrands() {
  INPUT=$1
  OUTPUT=$2

  echo "$ERRANDS" >> $INPUT
  $TCC_CMD -g errands -i $INPUT -o $OUTPUT

  sed -i -e 's/^/  /' $OUTPUT
  cat $OUTPUT
  echo ""
}

function echoNetworkTemplate() {
  OUTPUT=$1

  $TCC_CMD -g network-azs -o $OUTPUT

  sed -i -e 's/^/  /' $OUTPUT
  cat $OUTPUT
  echo ""
}

function applyChangesConfig() {
  ERRANDS=$(echo "$ERRANDS" | $JQ_CMD -r '.errands[] | select(.post_deploy==true) | .name')
  APPLY_CHANGES_CONFIG_YML=apply_changes_config.yml

  echo 'apply_changes_config: |' >> "$APPLY_CHANGES_CONFIG_YML"
  echo "  deploy_products: [\"$PRODUCT_NAME\"]" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "  errands:" >> "$APPLY_CHANGES_CONFIG_YML" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "    $PRODUCT_NAME:" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "      run_post_deploy:" >> "$APPLY_CHANGES_CONFIG_YML"

  for errand in $ERRANDS; do
    echo "        $errand: true" >> "$APPLY_CHANGES_CONFIG_YML"
  done

  echo "  ignore_warnings: true" >> "$APPLY_CHANGES_CONFIG_YML"

  echo "# Apply Changes Config for $PRODUCT_NAME are:"
  cat $APPLY_CHANGES_CONFIG_YML
  echo ""
}

CURL_CMD="$OM_CMD --env env/"${OPSMAN_ENV_FILE_NAME}" curl -s -p"

PRODUCTS=$($CURL_CMD /api/v0/staged/products)
PRODUCT_GUID=$(echo $PRODUCTS | $JQ_CMD -r --arg product_identifier $PRODUCT_NAME '.[] | select(.type == $product_identifier) | .guid')

## Download the product properties

PROPERTIES=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/properties)

## Download the resources
RESOURCES=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/resources)

## Download the errands
ERRANDS=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/errands)

## Cleanup all the stuff, and echo on the console
echo "product_config: |"
echo "  product-name: $PRODUCT_NAME"
echoNetworkTemplate "$PRODUCT_NAME-nw-azs.yml"
cleanAndEchoProperties "$PRODUCT_NAME-properties.json" "$PRODUCT_NAME-properties.yml"
cleanAndEchoResources "$PRODUCT_NAME-resources.json" "$PRODUCT_NAME-resources.yml"
cleanAndEchoErrands "$PRODUCT_NAME-errands.json" "$PRODUCT_NAME-errands.yml"
applyChangesConfig

## Clean-up the container
rm -rf $PRODUCT_NAME-*.*
