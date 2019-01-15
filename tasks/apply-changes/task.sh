#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

if [[ ! -z "$CONFIG_FILE_NAME" && null != "$CONFIG_FILE_NAME" ]]; then
  apply_changes_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < config/$CONFIG_FILE_NAME)

  deploy_products_type=$(echo "$apply_changes_config" | $JQ_CMD -r '.deploy_products | type')

  staged_products=$($OM_CMD -e env/$OPSMAN_ENV_FILE_NAME curl -s -p /api/v0/staged/products)

  if [[ "$deploy_products_type" == "array" ]]; then
    products=$(echo "$apply_changes_config" | $JQ_CMD -r '.deploy_products[]')

    for product in $(echo $products | sed "s/\n/ /g"); do
      product_guid=$(echo "$staged_products" | $JQ_CMD -r --arg product_name $product '.[] | select(.type == $product_name) | .guid')
      if [[ ! -z "$product_guid" ]]; then
        sed -i -e "s/$product/$product_guid/g" config/$CONFIG_FILE_NAME
      else
        echo "$product specified in the apply changes config, not found"
        exit 1
      fi
    done

    apply_changes_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < config/$CONFIG_FILE_NAME)
  fi

  $OM_CMD -e env/$OPSMAN_ENV_FILE_NAME curl -s -p /api/v0/installations -x POST -d "$apply_changes_config"
fi

$OM_CMD -e env/$OPSMAN_ENV_FILE_NAME apply-changes --ignore-warnings true
