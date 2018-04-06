#!/bin/bash

config=$(jq -n \
  --argjson allow_paid_service_plans ${ALLOW_PAID_SERVICE_PLANS:-false} \
  --argjson apply_open_security_group ${APPLY_OPEN_SECURITY_GROUP:-true} \
  --arg http_proxy $HTTP_PROXY \
  --arg newrelic_insights_base_url $NEWRELIC_INSIGHTS_BASE_URL \
  --arg newrelic_insights_insert_key $NEWRELIC_INSIGHTS_INSERT_KEY \
  --arg newrelic_insights_rpm_id $NEWRELIC_INSIGHTS_RPM_ID \
  --arg no_proxy $NO_PROXY \
  --arg nozzle_admin_password $NOZZLE_ADMIN_PASSWORD \
  --arg nozzle_admin_user ${NOZZLE_ADMIN_USER:-admin} \
  --argjson nozzle_app_detail_interval ${NOZZLE_APP_DETAIL_INTERVAL:-1} \
  --arg nozzle_excluded_deployments $NOZZLE_EXCLUDED_DEPLOYMENTS \
  --arg nozzle_excluded_jobs $NOZZLE_EXCLUDED_JOBS \
  --arg nozzle_excluded_origins $NOZZLE_EXCLUDED_ORIGINS \
  --arg nozzle_firehose_subscription_id ${NOZZLE_FIREHOSE_SUBSCRIPTION_ID:-"newrelic.firehose"} \
  --argjson nozzle_instances ${NOZZLE_INSTANCES:-3} \
  --arg nozzle_password $NOZZLE_PASSWORD \
  --arg nozzle_selected_events $NOZZLE_SELECTED_EVENTS \
  --argjson nozzle_skip_ssl ${NOZZLE_SKIP_SSL:-false} \
  --arg nozzle_traffic_controller_url $NOZZLE_TRAFFIC_CONTROLLER_URL \
  --arg nozzle_uaa_url $NOZZLE_UAA_URL \
  --arg nozzle_username ${NOZZLE_USERNAME:-"opentsdb-firehose-nozzle"} \
  --arg org ${ORG:-"nr-firehose-nozzle-org"} \
  --arg space ${SPACE:-"nr-firehose-nozzle-space"} \
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
    ".properties.newrelic_insights_base_url": {
      "value": $newrelic_insights_base_url
    },
    ".properties.newrelic_insights_rpm_id": {
      "value": $newrelic_insights_rpm_id
    },
    ".properties.newrelic_insights_insert_key": {
      "value": {
        "secret": $newrelic_insights_insert_key
      }
    },
    ".properties.nozzle_uaa_url": {
      "value": $nozzle_uaa_url
    },
    ".properties.nozzle_instances": {
      "value": $nozzle_instances
    },
    ".properties.nozzle_skip_ssl": {
      "value": $nozzle_skip_ssl
    },
    ".properties.nozzle_username": {
      "value": $nozzle_username
    },
    ".properties.nozzle_password": {
      "value": {
        "secret": $nozzle_password
      }
    },
    ".properties.nozzle_traffic_controller_url": {
      "value": $nozzle_traffic_controller_url
    },
    ".properties.nozzle_firehose_subscription_id": {
      "value": $nozzle_firehose_subscription_id
    },
    ".properties.nozzle_selected_events": {
      "value": $nozzle_selected_events
    },
    ".properties.nozzle_excluded_deployments": {
      "value": $nozzle_excluded_deployments
    },
    ".properties.nozzle_excluded_origins": {
      "value": $nozzle_excluded_origins
    },
    ".properties.nozzle_excluded_jobs": {
      "value": $nozzle_excluded_jobs
    },
    ".properties.nozzle_admin_user": {
      "value": $nozzle_admin_user
    },
    ".properties.nozzle_admin_password": {
      "value": {
        "secret": $nozzle_admin_password
      }
    },
    ".properties.nozzle_app_detail_interval": {
      "value": $nozzle_app_detail_interval
    },
    ".properties.http_proxy": {
      "value": $http_proxy
    },
    ".properties.no_proxy": {
      "value": $no_proxy
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
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name nr-firehose-nozzle \
  --product-properties "$config" \
  --product-network "$network_config"
