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
  --arg add_app_info ${ADD_APP_INFO:-false} \
  --arg allow_paid_service_plans ${ALLOW_PAID_SERVICE_PLANS:-true} \
  --arg api_endpoint ${API_ENDPOINT:-null} \
  --arg api_password ${API_PASSWORD:-null} \
  --arg api_user ${API_USER:-null} \
  --arg apply_open_security_group ${APPLY_OPEN_SECURITY_GROUP:-true} \
  --arg enable_event_tracing ${ENABLE_EVENT_TRACING:-false} \
  --arg events ${EVENTS:-null} \
  --arg extra_fields ${EXTRA_FIELDS:-null} \
  --arg firehose_subscription_id ${FIREHOSE_SUBSCRIPTION_ID:-null} \
  --arg org ${ORG:-"splunk-nozzle-org"} \
  --arg scale_out_nozzle ${SCALE_OUT_NOZZLE:-2} \
  --arg skip_ssl_validation_cf ${SKIP_SSL_VALIDATION_CF:-false} \
  --arg skip_ssl_validation_splunk ${SKIP_SSL_VALIDATION_SPLUNK:-false} \
  --arg space ${SPACE:-"splunk-nozzle-space"} \
  --arg splunk_host ${SPLUNK_HOST:-null} \
  --arg splunk_index ${SPLUNK_INDEX:-"main"} \
  --arg splunk_token ${SPLUNK_TOKEN:-null} \
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
  ".properties.splunk_host": {
    "value": $splunk_host
  },
  ".properties.splunk_token": {
    "value": {
      "secret": $splunk_token
    }
  },
  ".properties.skip_ssl_validation_splunk": {
    "value": $skip_ssl_validation_splunk
  },
  ".properties.splunk_index": {
    "value": $splunk_index
  },
  ".properties.api_endpoint": {
    "value": $api_endpoint
  },
  ".properties.api_user": {
    "value": $api_user
  },
  ".properties.api_password": {
    "value": {
      "secret": $api_password
    }
  },
  ".properties.skip_ssl_validation_cf": {
    "value": $skip_ssl_validation_cf
  },
  ".properties.events": {
    "value": $events
  },
  ".properties.scale_out_nozzle": {
    "value": $scale_out_nozzle
  },
  ".properties.firehose_subscription_id": {
    "value": $firehose_subscription_id
  },
  ".properties.extra_fields": {
    "value": $extra_fields
  },
  ".properties.add_app_info": {
    "value": $add_app_info
  },
  ".properties.enable_event_tracing": {
    "value": $enable_event_tracing
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
  --product-name splunk-nozzle \
  --product-properties "$properties_config" \
  --product-network "$network_config"
