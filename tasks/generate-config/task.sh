#!/bin/bash -e

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

chmod +x ./tile-config-convertor/tile-config-convertor_linux_amd64
TCC_CMD=./tile-config-convertor/tile-config-convertor_linux_amd64

function cleanAndEchoProperties {
  INPUT="properties.json"
  OUTPUT="properties.yml"

  echo "$PROPERTIES" >> $INPUT
  $TCC_CMD -g properties -i $INPUT -o $OUTPUT

  echo "# Properties for $PRODUCT_IDENTIFIER are:"
  cat $OUTPUT
  echo ""
}

function cleanAndEchoResources() {
  INPUT="resources.json"
  OUTPUT="resources.yml"

  echo "$RESOURCES" >> $INPUT
  $TCC_CMD -g resources -i $INPUT -o $OUTPUT

  echo "# Resources for $PRODUCT_IDENTIFIER are:"
  cat $OUTPUT
  echo ""
}

function cleanAndEchoErrands() {
  echo "# Errands for $PRODUCT_IDENTIFIER are:"
  ERRANDS_LIST=""
  for errand in $ERRANDS; do
    if [[ -z "$ERRANDS_LIST" ]]; then
      ERRANDS_LIST=$errand
    fi
    ERRANDS_LIST+=,$errand
  done
  echo $ERRANDS_LIST
  echo ""
}

function applyChangesConfig() {
  echo "# Apply Change Config for $PRODUCT_IDENTIFIER are:"

  APPLY_CHANGES_CONFIG_YML=apply_changes_config.yml

  echo 'apply_changes_config: |' >> "$APPLY_CHANGES_CONFIG_YML"
  echo "  deploy_products: [\"$PRODUCT_IDENTIFIER\"]" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "  errands:" >> "$APPLY_CHANGES_CONFIG_YML" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "    $PRODUCT_IDENTIFIER:" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "      run_post_deploy:" >> "$APPLY_CHANGES_CONFIG_YML"

  for errand in $ERRANDS; do
    echo "        $errand: true" >> "$APPLY_CHANGES_CONFIG_YML"
  done

  echo "  ignore_warnings: true" >> "$APPLY_CHANGES_CONFIG_YML"

  echo "# Apply Changes Config for $PRODUCT_IDENTIFIER are:"
  cat $APPLY_CHANGES_CONFIG_YML
  echo ""
}

function echoNetworkTemplate() {
  echo "# Network and AZ's template: "
  echo "product_network_azs: |
  network:
    name:
  service_network:
    name:
  other_availability_zones:
    - name:
    - name:
  singleton_availability_zone:
    name:"
  echo ""
}

CURL_CMD="$OM_CMD -k -t $OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -s -p"

PRODUCTS=$($CURL_CMD /api/v0/staged/products)
PRODUCT_GUID=$(echo $PRODUCTS | $JQ_CMD -r --arg product_identifier $PRODUCT_IDENTIFIER '.[] | select(.type == $product_identifier) | .guid')

## Download the product properties

PROPERTIES=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/properties)

## Download the resources
RESOURCES=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/resources)

## Download the errands
ERRANDS=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/errands | $JQ_CMD -r '.errands[] | select(.post_deploy==true) | .name')

## Cleanup all the stuff, and echo on the console
cleanAndEchoProperties
cleanAndEchoResources
cleanAndEchoErrands
applyChangesConfig
echoNetworkTemplate

## Clean-up the container
rm -rf $PRODUCT_IDENTIFIER.json
rm -rf $RESOURCES_YML
