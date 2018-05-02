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
  --arg mysql_roadmin_password ${MYSQL_ROADMIN_PASSWORD:-null} \
  --arg mysql_skip_name_resolve ${MYSQL_SKIP_NAME_RESOLVE:-true} \
  --arg push_apps_elasticsearch_logqueue_instance_count ${PUSH_APPS_ELASTICSEARCH_LOGQUEUE_INSTANCE_COUNT:-1} \
  --arg push_apps_ingestor_instance_count ${PUSH_APPS_INGESTOR_INSTANCE_COUNT:-1} \
  --arg push_apps_logs_retention_window ${PUSH_APPS_LOGS_RETENTION_WINDOW:-14} \
  --arg push_apps_metrics_retention_window ${PUSH_APPS_METRICS_RETENTION_WINDOW:-14} \
  --arg push_apps_mysql_logqueue_instance_count ${PUSH_APPS_MYSQL_LOGQUEUE_INSTANCE_COUNT:-1} \
  --arg push_apps_server_instance_count ${PUSH_APPS_SERVER_INSTANCE_COUNT:-1} \
'{
  ".mysql.roadmin_password": {
    "value": {
      "secret": $mysql_roadmin_password
    }
  },
  ".mysql.skip_name_resolve": {
    "value": $mysql_skip_name_resolve
  },
  ".push-apps.mysql_logqueue_instance_count": {
    "value": $push_apps_mysql_logqueue_instance_count
  },
  ".push-apps.elasticsearch_logqueue_instance_count": {
    "value": $push_apps_elasticsearch_logqueue_instance_count
  },
  ".push-apps.ingestor_instance_count": {
    "value": $push_apps_ingestor_instance_count
  },
  ".push-apps.server_instance_count": {
    "value": $push_apps_server_instance_count
  },
  ".push-apps.logs_retention_window": {
    "value": $push_apps_logs_retention_window
  },
  ".push-apps.metrics_retention_window": {
    "value": $push_apps_metrics_retention_window
  }
}'
)

resources_config="{
  \"elasticsearch_master\": {\"instances\": ${ELASTICSEARCH_MASTER_INSTANCES:-1}, \"instance_type\": { \"id\": \"${ELASTICSEARCH_MASTER_INSTANCE_TYPE:-large}\"}, \"persistent_disk\": { \"size_mb\": \"${ELASTICSEARCH_MASTER_PERSISTENT_DISK_MB:-10240}\"}},
  \"elasticsearch_data\": {\"instances\": ${ELASTICSEARCH_DATA_INSTANCES:-4}, \"instance_type\": { \"id\": \"${ELASTICSEARCH_DATA_INSTANCE_TYPE:-xlarge}\"}, \"persistent_disk\": { \"size_mb\": \"${ELASTICSEARCH_DATA_PERSISTENT_DISK_MB:-102400}\"}},
  \"redis\": {\"instances\": ${REDIS_INSTANCES:-1}, \"instance_type\": { \"id\": \"${REDIS_INSTANCE_TYPE:-medium}\"}, \"persistent_disk\": { \"size_mb\": \"${REDIS_PERSISTENT_DISK_MB:-102400}\"}}
}"

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
  --product-name $PRODUCT_IDENTIFIER \
  --product-properties "$properties_config" \
  --product-network "$network_config" \
  --product-resources "$resources_config"
