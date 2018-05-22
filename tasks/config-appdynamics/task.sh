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

properties_config=$($JQ_CMD -n \
  --arg allow_paid_service_plans "${ALLOW_PAID_SERVICE_PLANS:-false}" \
  --arg app_uri "${APP_URI:-"appdynamics-service-broker"}" \
  --argjson appd_plans "${APPD_PLANS:-[]}" \
  --arg appdynamics_service_broker_enable_global_access_to_plans "${APPDYNAMICS_SERVICE_BROKER_ENABLE_GLOBAL_ACCESS_TO_PLANS:-true}" \
  --arg apply_open_security_group "${APPLY_OPEN_SECURITY_GROUP:-true}" \
  --arg org "${ORG:-"appdynamics-org"}" \
  --arg space "${SPACE:-"appdynamics-space"}" \
'{
  ".properties.org": {
    "value": $org
  },
  ".properties.space": {
    "value": $space
  },
  ".properties.apply_open_security_group": {
    "value": $apply_open_security_group
  },
  ".properties.allow_paid_service_plans": {
    "value": $allow_paid_service_plans
  },
  ".properties.appdynamics_service_broker_enable_global_access_to_plans": {
    "value": $appdynamics_service_broker_enable_global_access_to_plans
  },
  ".properties.app_uri": {
    "value": $app_uri
  },
  ".properties.appd_plans": {
    "value": $appd_plans
  }
}'
)

network_config=$($JQ_CMD -n \
  --arg network_name "$NETWORK_NAME" \
  --arg other_azs "$OTHER_AZS" \
  --arg singleton_az "$SINGLETON_JOBS_AZ" \
'
  {
    "network": {
      "name": $network_name
    },
    "other_availability_zones": ($other_azs | split(",") | map({name: .})),
    "singleton_availability_zone": {
      "name": $singleton_az
    }
  }
'
)

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name "$PRODUCT_IDENTIFIER" \
  --product-properties "$properties_config" \
  --product-network "$network_config"
