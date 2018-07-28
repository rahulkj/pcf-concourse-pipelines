#!/bin/bash -e

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

function cleanAndEchoProperties {
  JSON="$(echo "$PROPERTIES")"
  OUTPUT="$PRODUCT_IDENTIFIER.json"

  for KEY in $(echo "$JSON" | "$JQ_CMD" -r '.[] | keys[]' | sed "s/,/ /g"); do
    IS_NON_CONFIGURABLE=$(echo "$JSON" | "$JQ_CMD" --arg "key" "$KEY" '.properties[$key] | select(.configurable==false)')
    if [ ! -z "$IS_NON_CONFIGURABLE" ]; then
      JSON=$(echo "$JSON" | "$JQ_CMD" --arg "key" "$KEY" 'del(.properties[$key])')
    fi
    unset IS_NON_CONFIGURABLE
  done

  DELETE=(type optional credential guid options configurable)

  for key in "${DELETE[@]}"; do
    JSON=$(echo "$JSON" | "$JQ_CMD" -L $PWD/pipelines-repo/tasks/generate-config --arg 'key' "$key" 'import "library" as lib;
      lib::walk(if type == "object" then del(.[$key]) else . end)')
  done

  echo "$JSON" | "$JQ_CMD" '.[]' > "$OUTPUT"

  echo "**Properties for $PRODUCT_IDENTIFIER are: **"
  ruby -ryaml -rjson -e 'puts YAML.dump(JSON.parse(STDIN.read))' < $OUTPUT
  echo ""
}

function cleanAndEchoResources() {

  KEYS=$(echo "$RESOURCES" | $JQ_CMD -r '.resources[] | .identifier' )

  RESOURCES_YML=resources.yml

  echo 'product_resources: |' >> "$RESOURCES_YML"
  echo '  ---' >> "$RESOURCES_YML"

  for key in $KEYS; do
    DEFAULT_INSTANCE_VALUE=$(echo "$RESOURCES" | $JQ_CMD --arg key $key '.resources[] | select(.identifier == $key) | .instances_best_fit' )
    DEFAULT_PERSISTENT_DISK_VALUE=$(echo "$RESOURCES" | $JQ_CMD -r --arg key $key '.resources[] | select(.identifier == $key) | .persistent_disk_mb' )
    DEFAULT_INSTANCE_TYPE_VALUE=$(echo "$RESOURCES" | $JQ_CMD -r --arg key $key '.resources[] | select(.identifier == $key) | .instance_type_best_fit' )

    echo "  $key:" >> "$RESOURCES_YML"
    echo "    instances: $DEFAULT_INSTANCE_VALUE" >> "$RESOURCES_YML"
    echo "    instance_type:" >> "$RESOURCES_YML"
    echo "      id: $DEFAULT_INSTANCE_TYPE_VALUE" >> "$RESOURCES_YML"

    if [[ $DEFAULT_PERSISTENT_DISK_VALUE != null ]]; then
      echo "    persistent_disk:" >> "$RESOURCES_YML"
      echo "      size_mb: \"$DEFAULT_PERSISTENT_DISK_VALUE\"" >> "$RESOURCES_YML"
    fi
  done

  echo "**Resources for $PRODUCT_IDENTIFIER are: **"
  cat $RESOURCES_YML
  echo ""
}

function cleanAndEchoErrands() {
  echo "**Errands for $PRODUCT_IDENTIFIER are: **"
  echo $ERRANDS
  echo ""
}

function echoNetworkTemplate() {
  echo "**Network and AZ's template: **"
  echo "product_network_azs: |
  ---
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
ERRANDS=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/errands | $JQ_CMD '.errands[] | select(.post_deploy==true) | .name')

## Cleanup all the stuff, and echo on the console
cleanAndEchoProperties
cleanAndEchoResources
cleanAndEchoErrands
echoNetworkTemplate

## Clean-up the container
rm -rf $PRODUCT_IDENTIFIER.json
rm -rf $RESOURCES_YML
