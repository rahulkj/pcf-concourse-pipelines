#!/bin/bash

config=$(jq -n \
  --argjson allow_paid_service_plans ${ALLOW_PAID_SERVICE_PLANS:-false} \
  --argjson apply_open_security_group ${APPLY_OPEN_SECURITY_GROUP:-false} \
  --arg dataflow_db_plan ${DATAFLOW_DB_PLAN:-"db-small"} \
  --arg dataflow_db_service ${DATAFLOW_DB_SERVICE:-"p.mysql"} \
  --arg db_service_name ${DB_SERVICE_NAME:-"p.mysql"} \
  --arg db_service_plan ${DB_SERVICE_PLAN:-"db-small"} \
  --arg org ${ORG:-"system"} \
  --argjson p_dataflow_enable_global_access_to_plans ${P_DATAFLOW_ENABLE_GLOBAL_ACCESS_TO_PLANS:-true} \
  --arg skipper_db_plan ${SKIPPER_DB_PLAN:"db-small"} \
  --arg skipper_db_service ${SKIPPER_DB_SERVICE:-"p.mysql"} \
  --arg space ${SPACE:-"p-dataflow"} \
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
    ".properties.p_dataflow_enable_global_access_to_plans": {
      "value": $p_dataflow_enable_global_access_to_plans
    },
    ".properties.db_service_name": {
      "value": $db_service_name
    },
    ".properties.db_service_plan": {
      "value": $db_service_plan
    },
    ".properties.dataflow_db_service": {
      "value": $dataflow_db_service
    },
    ".properties.dataflow_db_plan": {
      "value": $dataflow_db_plan
    },
    ".properties.skipper_db_service": {
      "value": $skipper_db_service
    },
    ".properties.skipper_db_plan": {
      "value": $skipper_db_plan
    }
  }'
)

network_config=$(jq -n \
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

om-linux \
  --target https://$OPS_MGR_PWD \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name p-dataflow \
  --product-properties "$config" \
  --product-network "$network_config"
