#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".properties.plan_collection": {
    "value": [
      {
        "name": "$PLAN_NAME",
        "description": "$PLAN_DESCRIPTION",
        "max_storage_mb": "$PLAN_MAX_STORAGE_MB",
        "max_user_connections": "$PLAN_MAX_USER_CONNECTIONS",
        "private": "$PLAN_PRIVATE"
      }
    ]
  },
  ".mysql.metrics_polling_frequency": {
    "value": "$METRICS_POLLING_FREQUENCY"
  },
  ".mysql.cluster_probe_timeout": {
    "value": "$CLUSTER_PROBE_TIMEOUT"
  },
  ".mysql.tmp_table_size": {
    "value": "$TMP_TABLE_SIZE"
  },
  ".mysql.table_open_cache": {
    "value": "$TABLE_OPEN_CACHE"
  },
  ".mysql.table_definition_cache": {
    "value": "$TABLE_DEFINITION_CACHE"
  },
  ".mysql.max_connections": {
    "value": "$MAX_CONNECTIONS"
  },
  ".mysql.binlog_expire_days": {
    "value": "$BINLOG_EXPIRE_DAYS"
  },
  ".mysql.cluster_name": {
    "value": "$CLUSTER_NAME"
  },
  ".mysql.innodb_strict_mode": {
    "value": "$INNODB_STRICT_MODE"
  },
  ".mysql.cli_history": {
    "value": "$ALLOW_CLI_HISTORY"
  },
  ".mysql.allow_remote_admin_access": {
    "value": "$ALLOW_REMOTE_ADMIN_ACCESS"
  },
  ".mysql.roadmin_password": {
    "value": {
      "secret": "$READONLY_ADMIN_PASSWORD"
    }
  },
  ".mysql.mysql_start_timeout": {
    "value": "$MYSQL_START_TIMEOUT"
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
  "mysql": {
    "instance_type": {"id": "$MYSQL_SERVER_INSTANCE_TYPE"},
    "instances" : $MYSQL_SERVER_INSTANCES,
    "persistent_disk_mb": "$MYSQL_PERSISTENT_DISK_MB"
  },
  "backup-prepare": {
    "instance_type": {"id": "$BACKUP_PREPARE_INSTANCE_TYPE"},
    "instances" : $BACKUP_PREPARE_INSTANCES,
    "persistent_disk_mb": "$BACKUP_PREPARE_PERSISTENT_DISK_MB"
  },
  "proxy": {
    "instance_type": {"id": "$MYSQL_PROXY_INSTANCE_TYPE"},
    "instances" : $MYSQL_PROXY_INSTANCES
  },
  ,
  "monitoring": {
    "instance_type": {"id": "$MONITORING_INSTANCE_TYPE"},
    "instances" : $MONITORING_INSTANCES
  },
  ,
  "cf-mysql-broker": {
    "instance_type": {"id": "$MYSQL_BROKER_INSTANCE_TYPE"},
    "instances" : $MYSQL_BROKER_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$PRODUCT_PROPERTIES" -pn "$PRODUCT_NETWORK_CONFIG" -pr "$PRODUCT_RESOURCE_CONFIG"

if [[ "$BACKUP_ENABLE" == "disable" ]]; then
BACKUP_OPTIONS_PROPERTIES=$(cat <<-EOF
{
  ".properties.backup_options": {
    "value": "$BACKUP_ENABLE"
  }
}
EOF
)

elif [[ "$BACKUP_ENABLE" == "enable" ]]; then
echo "Backup enabled..."
BACKUP_OPTIONS_PROPERTIES=$(cat <<-EOF
{
  ".properties.backup_options": {
    "value": "$BACKUP_ENABLE"
  },
  ".properties.backup_options.enable.cron_schedule": {
    "value": "$CRON_SCHEDULE"
  },
  ".properties.backup_options.enable.backup_all_masters": {
    "value": "$BACKUP_ALL_MASTERS"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$BACKUP_OPTIONS_PROPERTIES"

if [[ "$BACKUP_DESTINATION" == "none" ]]; then
echo "No backup destination..."
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "disable"
  }
}
EOF
)

elif [[ "$BACKUP_DESTINATION" == "s3" ]]; then
echo "Using s3 as the backup destination..."
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "enable"
  },
  ".properties.backups.enable.endpoint_url": {
    "value": "$S3_ENDPOINT"
  },
  ".properties.backups.enable.bucket_name": {
    "value": "$S3_BUCKET_NAME"
  },
  ".properties.backups.enable.bucket_path": {
    "value": "$S3_BUCKET_PATH"
  },
  ".properties.backups.enable.access_key_id": {
    "value": "$S3_ACCESS_KEY_ID"
  },
  ".properties.backups.enable.secret_access_key": {
    "value": {
      "secret": "$S3_SECRET_KEY"
    }
  }
}
EOF
)

elif [[ "$BACKUP_DESTINATION" == "scp" ]]; then
echo "Using scp as the backup destination..."
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "enable"
  },
  ".properties.backups.scp.user": {
    "value": "$SCP_USER"
  },
  ".properties.backups.scp.server": {
    "value": "$SCP_SERVER"
  },
  ".properties.backups.scp.destination": {
    "value": "$SCP_DESTINATION_DIR"
  },
  ".properties.backups.scp.scp_key": {
    "value": "$SCP_PRIVATE_KEY"
  },
  ".properties.backups.scp.port": {
    "value": "$SCP_PORT"
  }
}
EOF
)

elif [[ "$BACKUP_DESTINATION" == "azure" ]]; then
echo "Using azure as the backup destination..."
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "azure"
  },
  ".properties.backups.azure.storage_account": {
    "value": "$AZURE_STORAGE_ACCOUNT"
  },
  ".properties.backups.azure.storage_access_key": {
    "value": {
      "secret": "$AZURE_STORAGE_ACCESS_KEY"
    }
  },
  ".properties.backups.azure.container": {
    "value": "$AZURE_CONTAINER"
  },
  ".properties.backups.azure.container_path": {
    "value": "$AZURE_CONTAINER_PATH"
  },
  ".properties.backups.azure.base_url": {
    "value": "$AZURE_BASE_URL"
  }
}
EOF
)

elif [[ "$BACKUP_DESTINATION" == "gcs" ]]; then
echo "Using gcs as the backup destination..."
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "gcs"
  },
  ".properties.backups.gcs.service_account_json": {
    "value": {
      "secret": "$GCS_SERVICE_ACCOUNT_JSON"
    }
  },
  ".properties.backups.gcs.project_id": {
    "value": "$GCS_PROJECT_ID"
  },
  ".properties.backups.gcs.bucket_name": {
    "value": "$GCS_BUCKET_NAME"
  }
}
EOF
)

fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$BACKUP_PROPERTIES"

if [[ "$SYSLOG_ENABLED" == "enabled" ]]; then
SYSLOG_PROPERTIES=$(cat <<-EOF
{
  ".properties.syslog": {
    "value": "$SYSLOG_ENABLED"
  },
  ".properties.syslog.enabled.address": {
    "value": "$SYSLOG_ADDRESS"
  },
  ".properties.syslog.enabled.port": {
    "value": "$SYSLOG_PORT"
  }
}
EOF
)
elif [[ "$SYSLOG_ENABLED" == "disabled" ]]; then
SYSLOG_PROPERTIES=$(cat <<-EOF
{
  ".properties.syslog": {
    "value": "$SYSLOG_ENABLED"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$SYSLOG_PROPERTIES"

if [[ "$SERVER_ACTIVITY_LOGGING" == "enable" ]]; then
SERVER_ACTIVITY_LOGGING_PROPERTIES=$(cat <<-EOF
{
  ".properties.server_activity_logging": {
    "value": "$SERVER_ACTIVITY_LOGGING"
  },
  ".properties.server_activity_logging.enable.audit_logging_events": {
    "value": "$AUDIT_LOGGING_EVENTS"
  },
  ".properties.server_activity_logging.enable.server_audit_excluded_users_csv": {
    "value": "$SERVER_AUDIT_EXCLUDED_USERS_CSV"
  }
}
EOF
)
elif [[ "$SERVER_ACTIVITY_LOGGING" == "disable" ]]; then
SERVER_ACTIVITY_LOGGING_PROPERTIES=$(cat <<-EOF
{
  ".properties.server_activity_logging": {
    "value": "$SERVER_ACTIVITY_LOGGING"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$SERVER_ACTIVITY_LOGGING_PROPERTIES"


if [[ "$BUFFER_POOL_SIZE" == "percent" ]]; then
INNODB_BUFFER_POOL_PROPERTIES=$(cat <<-EOF
{
  ".properties.buffer_pool_size": {
    "value": "$BUFFER_POOL_SIZE"
  },
  ".properties.buffer_pool_size.percent.buffer_pool_size_percent": {
    "value": "$BUFFER_POOL_SIZE_PERCENT"
  }
}
EOF
)
elif [[ "$BUFFER_POOL_SIZE" == "bytes" ]]; then
INNODB_BUFFER_POOL_PROPERTIES=$(cat <<-EOF
{
  ".properties.buffer_pool_size": {
    "value": "$BUFFER_POOL_SIZE"
  },
  ".properties.buffer_pool_size.bytes.buffer_pool_size_bytes": {
    "value": "$BUFFER_POOL_SIZE_BYTES"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$INNODB_BUFFER_POOL_PROPERTIES"

if [[ "$OPTIONAL_PROTECTIONS" == "enable" ]]; then
OPTIONAL_PROTECTIONS_PROPERTIES=$(cat <<-EOF
{
  ".properties.optional_protections": {
    "value": "$OPTIONAL_PROTECTIONS"
  },
  ".properties.optional_protections.enable.recipient_email": {
    "value": "$RECEPIENT_EMAIL"
  },
  ".properties.optional_protections.enable.prevent_auto_rejoin": {
    "value": "$PREVENT_AUTO_JOIN"
  },
  ".properties.optional_protections.enable.replication_canary": {
    "value": "$REPLICATION_CANARY"
  },
  ".properties.optional_protections.enable.notify_only": {
    "value": "$NOTIFY_ONLY"
  },
  ".properties.optional_protections.enable.canary_poll_frequency": {
    "value": "$CANARY_POLL_FREQUENCY"
  },
  ".properties.optional_protections.enable.canary_write_read_delay": {
    "value": "$CANARY_WRITE_READ_DELAY"
  }
}
EOF
)
elif [[ "$OPTIONAL_PROTECTIONS" == "disable" ]]; then
OPTIONAL_PROTECTIONS_PROPERTIES=$(cat <<-EOF
{
  ".properties.optional_protections": {
    "value": "$OPTIONAL_PROTECTIONS"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$OPTIONAL_PROTECTIONS_PROPERTIES"
