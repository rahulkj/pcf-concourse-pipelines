#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux


PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".properties.metrics_polling_interval": {
    "value": "$METRICS_POLLING_INTERVAL"
  },
  ".redis-on-demand-broker.service_instance_limit": {
    "value": "$ON_DEMAND_SERVICE_INSTANCE_LIMIT"
  },
  ".cf-redis-broker.service_instance_limit": {
    "value": "$REDIS_BROKER_SERVICE_INSTANCE_LIMIT"
  },
  ".cf-redis-broker.redis_maxmemory": {
    "value": "$REDIS_MAX_MEMORY"
  },
  ".redis-on-demand-broker.vm_extensions": {
    "value": "$VM_EXTENSIONS"
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
  },
  "service_network": {
    "name": "$SERVICES_NETWORK"
  }
}
EOF
)

PRODUCT_RESOURCE_CONFIG=$(cat <<-EOF
{
  "redis-on-demand-broker": {
    "instance_type": {"id": "automatic"},
    "instances": $REDIS_ON_DEMAND_BROKER_INSTANCES,
    "persistent_disk": {"size_mb":"$REDIS_ON_DEMAND_BROKER_DISK_SIZE"}
  },
  "cf-redis-broker": {
    "instance_type": {"id": "automatic"},
    "instances": $CF_REDIS_BROKER_INSTANCES,
    "persistent_disk": {"size_mb":"$CF_REDIS_BROKER_DISK_SIZE"}
  },
  "dedicated-node": {
    "instance_type": {"id": "automatic"},
    "instances": $DEDICATED_NODE_INSTANCES,
    "persistent_disk": {"size_mb":"$DEDICATED_NODE_DISK_SIZE"}
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG" -p "$PRODUCT_PROPERTIES" -pr "$PRODUCT_RESOURCE_CONFIG"


if [[ "$SYSLOG_SELECTOR" == "Yes" ]]; then
SYSLOG_PROPERTIES=$(cat <<-EOF
{
  ".properties.syslog_selector": {
    "value": "$SYSLOG_SELECTOR"
  },
  ".properties.syslog_selector.active.syslog_address": {
    "value": "$SYSLOG_ADDRESS"
  },
  ".properties.syslog_selector.active.syslog_port": {
    "value": "$SYSLOG_PORT"
  },
  ".properties.syslog_selector.active.syslog_transport": {
    "value": "$SYSLOG_PROTOCOL"
  }
}
EOF
)
elif [[ "$SYSLOG_SELECTOR" == "No" ]]; then
SYSLOG_PROPERTIES=$(cat <<-EOF
{
  ".properties.syslog_selector": {
    "value": "$SYSLOG_SELECTOR"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$SYSLOG_PROPERTIES"

if [[ "$BACKUP_SELECTOR" == "No Backups" ]]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector": {
    "value": "$BACKUP_SELECTOR"
  }
}
EOF
)
elif [[ "$BACKUP_SELECTOR" == "S3 Backups" ]]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector.s3.access_key_id": {
    "value": "$S3_ACCESS_KEY_ID"
  },
  ".properties.backups_selector.s3.secret_access_key": {
    "value": "$S3_SECRET_ACCESS_KEY"
  },
  ".properties.backups_selector.s3.endpoint_url": {
    "value": "$S3_ENDPOINT_URL"
  },
  ".properties.backups_selector.s3.region": {
    "value": "$S3_REGION"
  },
  ".properties.backups_selector.s3.signature_version": {
    "value": "$S3_SIGNATURE_VERSION"
  },
  ".properties.backups_selector.s3.bucket_name": {
    "value": "$S3_BUCKET_NAME"
  },
  ".properties.backups_selector.s3.path": {
    "value": "$S3_PATH"
  },
  ".properties.backups_selector.s3.cron_schedule": {
    "value": "$S3_CRON_SCHEDULE"
  },
  ".properties.backups_selector.s3.bg_save_timeout": {
    "value": "$S3_BG_SAVE_TIMEOUT"
  }
}
EOF
)
elif [[ "$BACKUP_SELECTOR" == "SCP Backups" ]]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector.scp.server": {
    "value": "$SCP_SERVER"
  },
  ".properties.backups_selector.scp.user": {
    "value": "$SCP_USERNAME"
  },
  ".properties.backups_selector.scp.key": {
    "value": "$SCP_SSH_KEY"
  },
  ".properties.backups_selector.scp.path": {
    "value": "$SCP_PATH"
  },
  ".properties.backups_selector.scp.port": {
    "value": "$SCP_PORT"
  },
  ".properties.backups_selector.scp.cron_schedule": {
    "value": "$SCP_CRON_SCHEDULE"
  },
  ".properties.backups_selector.scp.bg_save_timeout": {
    "value": "$SCP_BG_SAVE_TIMEOUT"
  },
  ".properties.backups_selector.scp.fingerprint": {
    "value": "$SCP_FINGERPRINT"
  }
}
EOF
)
elif [[ "$BACKUP_SELECTOR" == "Azure Backups" ]]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector.azure.account": {
    "value": "$AZURE_ACCOUNT"
  },
  ".properties.backups_selector.azure.storage_access_key": {
    "value": "$AZURE_STORAGE_ACCESS_KEY"
  },
  ".properties.backups_selector.azure.path": {
    "value": "$AZURE_PATH"
  },
  ".properties.backups_selector.azure.cron_schedule": {
    "value": "$AZURE_CRON_SCHEDULE"
  },
  ".properties.backups_selector.azure.bg_save_timeout": {
    "value": "$AZURE_BG_SAVE_TIMEOUT"
  },
  ".properties.backups_selector.azure.container": {
    "value": "$AZURE_CONTAINER"
  },
  ".properties.backups_selector.azure.blob_store_base_url": {
    "value": "$AZURE_BLOB_STORE_BASE_URL"
  }
}
EOF
)
elif [[ "$BACKUP_SELECTOR" == "Google Cloud Storage Backups" ]]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector.gcs.project_id": {
    "value": "$GCS_PROJECT_ID"
  },
  ".properties.backups_selector.gcs.bucket_name": {
    "value": "$GCS_BUCKET_NAME"
  },
  ".properties.backups_selector.gcs.service_account_json": {
    "value": "$GCS_SERVICE_ACCOUNT_JSON"
  },
  ".properties.backups_selector.gcs.cron_schedule": {
    "value": "$GCS_CRON_SCHEDULE"
  },
  ".properties.backups_selector.gcs.bg_save_timeout": {
    "value": "$GCS_BG_SAVE_TIMEOUT"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$BACKUP_PROPERTIES"

if [[ "$SMALL_PLAN_SELECTOR" == "Plan Active" ]]; then
SMALL_PLAN_SETTINGS=$(cat <<-EOF
{
  ".properties.small_plan_selector": {
    "value": "$SMALL_PLAN_SELECTOR"
  },
  ".properties.small_plan_selector.active.name": {
    "value": "$SMALL_PLAN_NAME"
  },
  ".properties.small_plan_selector.active.description": {
    "value": "$SMALL_PLAN_DESCRIPTION"
  },
  ".properties.small_plan_selector.active.cf_service_access": {
    "value": "$SMALL_PLAN_SERVICE_ACCESS"
  },
  ".properties.small_plan_selector.active.az_single_select": {
    "value": "$SMALL_PLAN_AZ"
  },
  ".properties.small_plan_selector.active.vm_type": {
    "value": "$SMALL_PLAN_VM_TYPE"
  },
  ".properties.small_plan_selector.active.disk_size": {
    "value": "$SMALL_PLAN_DISK_SIZE"
  },
  ".properties.small_plan_selector.active.timeout": {
    "value": "$SMALL_PLAN_TIMEOUT"
  },
  ".properties.small_plan_selector.active.tcp_keepalive": {
    "value": "$SMALL_PLAN_TCP_KEEP_ALIVE"
  },
  ".properties.small_plan_selector.active.maxclients": {
    "value": "$SMALL_PLAN_MAX_CLIENTS"
  },
  ".properties.small_plan_selector.active.lua_scripting": {
    "value": "$SMALL_PLAN_LUA_SCRIPTING"
  },
  ".properties.small_plan_selector.active.instance_limit": {
    "value": "$SMALL_PLAN_INSTANCE_LIMIT"
  }
}
EOF
)
elif [[ "$SMALL_PLAN_SELECTOR" == "Plan Inactive" ]]; then
SMALL_PLAN_SETTINGS=$(cat <<-EOF
{
  ".properties.small_plan_selector": {
    "value": "$SMALL_PLAN_SELECTOR"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$SMALL_PLAN_SETTINGS"

if [[ "$MEDIUM_PLAN_SELECTOR" == "Plan Active" ]]; then
MEDIUM_PLAN_SETTINGS=$(cat <<-EOF
{
  ".properties.medium_plan_selector": {
    "value": "$MEDIUM_PLAN_SELECTOR"
  },
  ".properties.medium_plan_selector.active.name": {
    "value": "$MEDIUM_PLAN_NAME"
  },
  ".properties.medium_plan_selector.active.description": {
    "value": "$MEDIUM_PLAN_DESCRIPTION"
  },
  ".properties.medium_plan_selector.active.cf_service_access": {
    "value": "$MEDIUM_PLAN_SERVICE_ACCESS"
  },
  ".properties.medium_plan_selector.active.az_single_select": {
    "value": "$MEDIUM_PLAN_AZ"
  },
  ".properties.medium_plan_selector.active.vm_type": {
    "value": "$MEDIUM_PLAN_VM_TYPE"
  },
  ".properties.medium_plan_selector.active.disk_size": {
    "value": "$MEDIUM_PLAN_DISK_TYPE"
  },
  ".properties.medium_plan_selector.active.timeout": {
    "value": "$MEDIUM_PLAN_TIMEOUT"
  },
  ".properties.medium_plan_selector.active.tcp_keepalive": {
    "value": "$MEDIUM_PLAN_TCP_KEEPALIVE"
  },
  ".properties.medium_plan_selector.active.maxclients": {
    "value": "$MEDIUM_PLAN_MAX_CLIENTS"
  },
  ".properties.medium_plan_selector.active.lua_scripting": {
    "value": "$MEDIUM_PLAN_LUA_SCRIPTING"
  },
  ".properties.medium_plan_selector.active.instance_limit": {
    "value": "$MEDIUM_PLAN_INSTANCE_LIMIT"
  }
}
EOF
)
elif [[ "$MEDIUM_PLAN_SELECTOR" == "Plan Inactive" ]]; then
MEDIUM_PLAN_SETTINGS=$(cat <<-EOF
{
  ".properties.medium_plan_selector": {
    "value": "$MEDIUM_PLAN_SELECTOR"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$MEDIUM_PLAN_SETTINGS"

if [[ "$LARGE_PLAN_SELECTOR" == "Plan Active" ]]; then
LARGE_PLAN_SETTINGS=$(cat <<-EOF
{
  ".properties.large_plan_selector": {
    "value": "$LARGE_PLAN_SELECTOR"
  },
  ".properties.large_plan_selector.active.name": {
    "value": "$LARGE_PLAN_NAME"
  },
  ".properties.large_plan_selector.active.description": {
    "value": "$LARGE_PLAN_DESCRIPTION"
  },
  ".properties.large_plan_selector.active.cf_service_access": {
    "value": "$LARGE_PLAN_SERVICE_ACCESS"
  },
  ".properties.large_plan_selector.active.az_single_select": {
    "value": "$LARGE_PLAN_AZ"
  },
  ".properties.large_plan_selector.active.vm_type": {
    "value": "$LARGE_PLAN_VM_TYPE"
  },
  ".properties.large_plan_selector.active.disk_size": {
    "value": "$LARGE_PLAN_DISK_SIZE"
  },
  ".properties.large_plan_selector.active.timeout": {
    "value": "$LARGE_PLAN_TIMEOUT"
  },
  ".properties.large_plan_selector.active.tcp_keepalive": {
    "value": "$LARGE_PLAN_KEEPALIVE"
  },
  ".properties.large_plan_selector.active.maxclients": {
    "value": "$LARGE_PLAN_MAX_CLIENTS"
  },
  ".properties.large_plan_selector.active.lua_scripting": {
    "value": "$LARGE_PLAN_LUA_SCRIPTING"
  },
  ".properties.large_plan_selector.active.instance_limit": {
    "value": "$LARGE_PLAN_INSTANCE_LIMIT"
  }
}
EOF
)
elif [[ "$LARGE_PLAN_SELECTOR" == "Plan Inactive" ]]; then
LARGE_PLAN_SETTINGS=$(cat <<-EOF
{
  ".properties.large_plan_selector": {
    "value": "$LARGE_PLAN_SELECTOR"
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$LARGE_PLAN_SETTINGS"
