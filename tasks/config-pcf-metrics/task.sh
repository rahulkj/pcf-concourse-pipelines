#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".mysql_monitor.notifications_email": {
    "value": "$MYSQL_MONITOR_EMAIL"
  },
  ".push-apps.mysql_logqueue_instance_count": {
    "value": "$MYSQL_LOGQUEUE_INSTANCE_COUNT"
  },
  ".push-apps.elasticsearch_logqueue_instance_count": {
    "value": "$ELASTICSEARCH_LOGQUEUE_INSTANCE_COUNT"
  },
  ".push-apps.ingestor_instance_count": {
    "value": "$INGESTOR_INSTANCE_COUNT"
  }
}
EOF
)

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PRODUCT_NETWORK_CONFIG=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $BALANCE_JOB_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

PRODUCT_RESOURCE_CONFIG=$(cat <<-EOF
{
  "elasticsearch_master": {
    "instance_type": {"id": "$ELASTICSEARCH_MASTER_INSTANCE_TYPE"},
    "instances": $ELASTICSEARCH_MASTER_INSTANCES,
    "persistent_disk": {"size_mb":"$ELASTICSEARCH_MASTER_PERSISTENT_DISK_SIZE"}
  },
  "elasticsearch_data": {
    "instance_type": {"id": "$ELASTICSEARCH_DATA_INSTANCE_TYPE"},
    "instances": $ELASTICSEARCH_DATA_INSTANCES,
    "persistent_disk": {"size_mb":"$ELASTICSEARCH_DATA_PERSISTENT_DISK_SIZE"}
  },
  "mysql_server": {
    "instance_type": {"id": "$MYSQL_SERVER_INSTANCE_TYPE"},
    "instances": $MYSQL_SERVER_INSTANCES,
    "persistent_disk": {"size_mb":"$MYSQL_SERVER_PERSISTENT_DISK_SIZE"}
  },
  "mysql_proxy": {
    "instance_type": {"id": "$MYSQL_PROXY_INSTANCE_TYPE"},
    "instances": $MYSQL_PROXY_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG" -p "$PRODUCT_PROPERTIES"  -pr "$PRODUCT_RESOURCE_CONFIG"
