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
  --arg deploy_pcf_event_alerts_instance_count "${DEPLOY_PCF_EVENT_ALERTS_INSTANCE_COUNT:-1}" \
  --arg mysql "${MYSQL:-"internal"}" \
  --arg mysql_external_database "${MYSQL_EXTERNAL_DATABASE}" \
  --arg mysql_external_host "${MYSQL_EXTERNAL_HOST}" \
  --arg mysql_external_password "${MYSQL_EXTERNAL_PASSWORD}" \
  --arg mysql_external_port "${MYSQL_EXTERNAL_PORT}" \
  --arg mysql_external_username "${MYSQL_EXTERNAL_USERNAME}" \
  --arg mysql_internal_plan_name "${MYSQL_INTERNAL_PLAN_NAME:-"db-small"}" \
'
if $mysql == "internal" then
{
  ".properties.mysql": {
    "value": "Mysql Service"
  }
}
elif $mysql == "external" then
{
  ".properties.mysql": {
    "value": "External DB"
  }
}
else .
end
+
if $mysql == "internal" then
{
  ".properties.mysql.internal.plan_name": {
    "value": $mysql_internal_plan_name
  }
}
elif $mysql == "external" then
{
  ".properties.mysql.external.host": {
    "value": $mysql_external_host
  },
  ".properties.mysql.external.port": {
    "value": $mysql_external_port
  },
  ".properties.mysql.external.username": {
    "value": $mysql_external_username
  },
  ".properties.mysql.external.password": {
    "value": {
      "secret": $mysql_external_password
    }
  },
  ".properties.mysql.external.database": {
    "value": $mysql_external_database
  }
}
else .
end
+
{
  ".deploy-pcf-event-alerts.instance_count": {
    "value": $deploy_pcf_event_alerts_instance_count
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
