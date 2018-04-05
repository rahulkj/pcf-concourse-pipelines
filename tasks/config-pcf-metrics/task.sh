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

PRODUCT_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --argjson mysql_logqueue_instance_count $MYSQL_LOGQUEUE_INSTANCE_COUNT \
    --argjson elasticsearch_logqueue_instance_count $ELASTICSEARCH_LOGQUEUE_INSTANCE_COUNT \
    --argjson ingestor_instance_count $INGESTOR_INSTANCE_COUNT \
    --argjson server_instance_count $SERVER_INSTANCE_COUNT \
    --argjson logs_retention_window $LOGS_RETENTION_WINDOW \
    --argjson metrics_retention_window $METRICS_RETENTION_WINDOW \
    '. +
    {
      ".push-apps.mysql_logqueue_instance_count": {
        "value": $mysql_logqueue_instance_count
      },
      ".push-apps.elasticsearch_logqueue_instance_count": {
        "value": $elasticsearch_logqueue_instance_count
      },
      ".push-apps.ingestor_instance_count": {
        "value": $ingestor_instance_count
      },
      ".push-apps.server_instance_count": {
        "value": $server_instance_count
      },
      ".push-apps.logs_retention_window": {
        "value": $logs_retention_window
      },
      ".push-apps.metrics_retention_window": {
        "value": $metrics_retention_window
      }
    }
    '
)

PRODUCT_NETWORK=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg singleton_jobs_az "$SINGLETON_JOBS_AZ" \
    --arg other_azs "$OTHER_AZS" \
    --arg network_name "$NETWORK_NAME" \
    '. +
    {
      "singleton_availability_zone": {
        "name": $singleton_jobs_az
      },
      "other_availability_zones": ($other_azs | split(",") | map({name: .})),
      "network": {
        "name": $network_name
      }
    }
    '
)

PRODUCT_RESOURCE=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg elasticsearch_master_instance_type "$ELASTICSEARCH_MASTER_INSTANCE_TYPE" \
    --argjson elasticsearch_master_instances $ELASTICSEARCH_MASTER_INSTANCES \
    --arg elasticsearch_master_persistent_disk_size "$ELASTICSEARCH_MASTER_PERSISTENT_DISK_SIZE" \
    --arg elasticsearch_data_instance_type "$ELASTICSEARCH_DATA_INSTANCE_TYPE" \
    --argjson elasticsearch_data_instances $ELASTICSEARCH_DATA_INSTANCES \
    --arg elasticsearch_data_persistent_disk_size "$ELASTICSEARCH_DATA_PERSISTENT_DISK_SIZE" \
    --arg redis_instance_type "$REDIS_INSTANCE_TYPE" \
    --argjson redis_instances $REDIS_INSTANCES \
    --arg redis_disk_size "$REDIS_DISK_SIZE" \
    --arg mysql_instance_type "$MYSQL_INSTANCE_TYPE" \
    --arg mysql_persistent_disk_size "$MYSQL_PERSISTENT_DISK_SIZE" \
    '. +
    {
      "elasticsearch_master": {
        "instance_type": {"id": $elasticsearch_master_instance_type},
        "instances": $elasticsearch_master_instances,
        "persistent_disk": {"size_mb": $elasticsearch_master_persistent_disk_size}
      },
      "elasticsearch_data": {
        "instance_type": {"id": $elasticsearch_data_instance_type},
        "instances": $elasticsearch_data_instances,
        "persistent_disk": {"size_mb": $elasticsearch_data_persistent_disk_size}
      },
      "redis": {
        "instance_type": {"id": $redis_instance_type},
        "instances": $redis_instances,
        "persistent_disk": {"size_mb": $redis_disk_size}
      },
      "mysql": {
        "instance_type": {"id": $mysql_instance_type},
        "persistent_disk": {"size_mb": $mysql_persistent_disk_size}
      }
    }'
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK" -p "$PRODUCT_PROPERTIES"  -pr "$PRODUCT_RESOURCE"
