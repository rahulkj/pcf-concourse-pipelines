#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

RESPONSE=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p /api/v0/deployed/director/credentials/nats_credentials`

NATS_USERNAME=`echo $RESPONSE | jq '.credential.value.identity' | tr -d '"'`
NATS_PASSWORD=`echo $RESPONSE | jq '.credential.value.password' | tr -d '"'`

PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".maintenance.retention_period": {
    "value": "$RETENTION_PERIOD"
  },
  ".parser.outputs": {
    "value": "$PARSER_OUTPUTS"
  },
  ".ingestor.nats_credentials": {
    "value": {
      "identity": "$NATS_USERNAME",
      "password": "$NATS_PASSWORD"
    }
  },
  ".ingestor.max_queue_length": {
    "value": "$MAX_QUEUE_LENGTH"
  },
  ".firehose-to-syslog.event_types": {
    "value": [
      $EVENT_TYPES
    ]
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
    "instance_type": {"id": "$ELASTIC_SEARCH_INSTANCE_TYPE"},
    "instances": $ELASTIC_SEARCH_INSTANCES,
    "persistent_disk_mb": "$ELASTICSEARCH_MASTER_PERSISTENT_DISK_MB"
  },
  "elasticsearch_data": {
    "instance_type": {"id": "$ELASTIC_DATA_INSTANCE_TYPE"},
    "instances": $ELASTIC_DATA_INSTANCES,
    "persistent_disk_mb": "$ELASTICSEARCH_DATA_PERSISTENT_DISK_MB"
  },
  "parser": {
    "instance_type": {"id": "$PARSER_INSTANCE_TYPE"},
    "instances": $PARSER_INSTANCES
  },
  "ingestor": {
    "instance_type": {"id": "$INGESTOR_INSTANCE_TYPE"},
    "instances": $INGESTOR_INSTANCES
  },
  "kibana": {
    "instance_type": {"id": "$KIBANA_INSTANCE_TYPE"},
    "instances": $KIBANA_INSTANCES
  },
  "monitor": {
    "instance_type": {"id": "$MONITOR_INSTANCE_TYPE"},
    "instances": $MONITOR_INSTANCES,
    "persistent_disk_mb": "$MONITOR_PERSISTENT_DISK_MB"
  },
  "firehose-to-syslog": {
    "instance_type": {"id": "$FIREHOSE_TO_SYSLOG_INSTANCE_TYPE"},
    "instances": $FIREHOSE_TO_SYSLOG_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG" -p "$PRODUCT_PROPERTIES"  -pr "$PRODUCT_RESOURCE_CONFIG"
