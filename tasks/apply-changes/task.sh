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

if [[ ! -z "$APPLY_CHANGES_CONFIG" && null != "$APPLY_CHANGES_CONFIG" ]]; then
  echo "$APPLY_CHANGES_CONFIG" > apply_changes_config.yml
  apply_changes_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < apply_changes_config.yml)

  deploy_products_type=$(echo "$apply_changes_config" | jq -r '.deploy_products | type')

  staged_products=$($OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -s -p /api/v0/staged/products)

  if [[ "$deploy_products_type" == "array" ]]; then
    products=$(echo "$apply_changes_config" | jq -r '.deploy_products[]')

    for product in $(echo $products | sed "s/\n/ /g"); do
      product_guid=$(echo "$staged_products" | jq -r --arg product_name $product '.[] | select(.type == $product_name) | .guid')
      sed -i -e "s/$product/$product_guid/g" apply_changes_config.yml
    done

    apply_changes_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < apply_changes_config.yml)
  fi

  rm -rf apply_changes_config.*

  $OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -s -p /api/v0/installations -x POST -d "$apply_changes_config"
fi

$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD apply-changes --ignore-warnings true
