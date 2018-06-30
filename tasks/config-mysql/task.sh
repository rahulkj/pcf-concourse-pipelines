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
  --arg cf_mysql_broker_allow_table_locks ${CF_MYSQL_BROKER_ALLOW_TABLE_LOCKS:-true} \
  --arg cf_mysql_broker_bind_hostname ${CF_MYSQL_BROKER_BIND_HOSTNAME:-''} \
  --arg cf_mysql_broker_quota_enforcer_pause ${CF_MYSQL_BROKER_QUOTA_ENFORCER_PAUSE:-30} \
  --arg mysql_allow_local_infile ${MYSQL_ALLOW_LOCAL_INFILE:-true} \
  --arg mysql_allow_remote_admin_access ${MYSQL_ALLOW_REMOTE_ADMIN_ACCESS:-false} \
  --arg mysql_binlog_expire_days ${MYSQL_BINLOG_EXPIRE_DAYS:-7} \
  --arg mysql_cli_history ${MYSQL_CLI_HISTORY:-true} \
  --arg mysql_cluster_name ${MYSQL_CLUSTER_NAME:-"cf-mariadb-galera-cluster"} \
  --arg mysql_cluster_probe_timeout ${MYSQL_CLUSTER_PROBE_TIMEOUT:-10} \
  --arg mysql_innodb_large_prefix_enabled ${MYSQL_INNODB_LARGE_PREFIX_ENABLED:-true} \
  --arg mysql_innodb_strict_mode ${MYSQL_INNODB_STRICT_MODE:-true} \
  --arg mysql_max_connections ${MYSQL_MAX_CONNECTIONS:-1500} \
  --arg mysql_metrics_polling_frequency ${MYSQL_METRICS_POLLING_FREQUENCY:-30} \
  --arg mysql_mysql_start_timeout ${MYSQL_MYSQL_START_TIMEOUT:-60} \
  --arg mysql_roadmin_password ${MYSQL_ROADMIN_PASSWORD:-''} \
  --arg mysql_skip_name_resolve ${MYSQL_SKIP_NAME_RESOLVE:-true} \
  --arg mysql_table_definition_cache ${MYSQL_TABLE_DEFINITION_CACHE:-8192} \
  --arg mysql_table_open_cache ${MYSQL_TABLE_OPEN_CACHE:-2000} \
  --arg mysql_tmp_table_size ${MYSQL_TMP_TABLE_SIZE:-33554432} \
  --arg backup_options ${BACKUP_OPTIONS:-"enable"} \
  --arg backup_options_enable_backup_all_masters ${BACKUP_OPTIONS_ENABLE_BACKUP_ALL_MASTERS:-false} \
  --arg backup_options_enable_cron_schedule \"${BACKUP_OPTIONS_ENABLE_CRON_SCHEDULE:-"0 0 * * *"}\" \
  --arg backups ${BACKUPS:-"disable"} \
  --arg backups_azure_base_url ${BACKUPS_AZURE_BASE_URL:-''} \
  --arg backups_azure_container ${BACKUPS_AZURE_CONTAINER:-''} \
  --arg backups_azure_container_path ${BACKUPS_AZURE_CONTAINER_PATH:-''} \
  --arg backups_azure_storage_access_key ${BACKUPS_AZURE_STORAGE_ACCESS_KEY:-''} \
  --arg backups_azure_storage_account ${BACKUPS_AZURE_STORAGE_ACCOUNT:-''} \
  --arg backups_enable_access_key_id ${BACKUPS_ENABLE_ACCESS_KEY_ID:-''} \
  --arg backups_enable_bucket_name ${BACKUPS_ENABLE_BUCKET_NAME:-''} \
  --arg backups_enable_bucket_path ${BACKUPS_ENABLE_BUCKET_PATH:-''} \
  --arg backups_enable_endpoint_url ${BACKUPS_ENABLE_ENDPOINT_URL:-''} \
  --arg backups_enable_region ${BACKUPS_ENABLE_REGION:-''} \
  --arg backups_enable_secret_access_key ${BACKUPS_ENABLE_SECRET_ACCESS_KEY:-''} \
  --arg backups_gcs_bucket_name ${BACKUPS_GCS_BUCKET_NAME:-''} \
  --arg backups_gcs_project_id ${BACKUPS_GCS_PROJECT_ID:-''} \
  --argjson backups_gcs_service_account_json ${BACKUPS_GCS_SERVICE_ACCOUNT_JSON:-''} \
  --arg backups_scp_destination ${BACKUPS_SCP_DESTINATION:-''} \
  --arg backups_scp_port ${BACKUPS_SCP_PORT:-22} \
  --arg backups_scp_scp_key ${BACKUPS_SCP_SCP_KEY:-''} \
  --arg backups_scp_server ${BACKUPS_SCP_SERVER:-''} \
  --arg backups_scp_user ${BACKUPS_SCP_USER:-''} \
  --arg buffer_pool_size ${BUFFER_POOL_SIZE:-"percent"} \
  --arg buffer_pool_size_bytes_buffer_pool_size_bytes ${BUFFER_POOL_SIZE_BYTES_BUFFER_POOL_SIZE_BYTES:-1} \
  --arg buffer_pool_size_percent_buffer_pool_size_percent ${BUFFER_POOL_SIZE_PERCENT_BUFFER_POOL_SIZE_PERCENT:-50} \
  --arg innodb_flush_log_at_trx_commit ${INNODB_FLUSH_LOG_AT_TRX_COMMIT:-"one"} \
  --arg optional_protections ${OPTIONAL_PROTECTIONS:-"enable"} \
  --arg optional_protections_enable_canary_poll_frequency ${OPTIONAL_PROTECTIONS_ENABLE_CANARY_POLL_FREQUENCY:-30} \
  --arg optional_protections_enable_canary_write_read_delay ${OPTIONAL_PROTECTIONS_ENABLE_CANARY_WRITE_READ_DELAY:-20} \
  --arg optional_protections_enable_notify_only ${OPTIONAL_PROTECTIONS_ENABLE_NOTIFY_ONLY:-false} \
  --arg optional_protections_enable_prevent_auto_rejoin ${OPTIONAL_PROTECTIONS_ENABLE_PREVENT_AUTO_REJOIN:-false} \
  --arg optional_protections_enable_recipient_email ${OPTIONAL_PROTECTIONS_ENABLE_RECIPIENT_EMAIL:-''} \
  --arg optional_protections_enable_replication_canary ${OPTIONAL_PROTECTIONS_ENABLE_REPLICATION_CANARY:-true} \
  --argjson plan_collection ${PLAN_COLLECTION} \
  --arg server_activity_logging ${SERVER_ACTIVITY_LOGGING:-"enable"} \
  --arg server_activity_logging_enable_audit_logging_events ${SERVER_ACTIVITY_LOGGING_ENABLE_AUDIT_LOGGING_EVENTS:-"connect,query"} \
  --arg server_activity_logging_enable_server_audit_excluded_users_csv ${SERVER_ACTIVITY_LOGGING_ENABLE_SERVER_AUDIT_EXCLUDED_USERS_CSV:-''} \
  --arg syslog ${SYSLOG:-"disabled"} \
  --arg syslog_enabled_address ${SYSLOG_ENABLED_ADDRESS:-''} \
  --arg syslog_enabled_port ${SYSLOG_ENABLED_PORT:-6514} \
  --arg syslog_enabled_protocol ${SYSLOG_ENABLED_PROTOCOL:-"tcp"} \
  --arg proxy_shutdown_delay ${PROXY_SHUTDOWN_DELAY:-0} \
  --arg proxy_startup_delay ${PROXY_STARTUP_DELAY:-0} \
  --arg proxy_static_ips ${PROXY_STATIC_IPS:-''} \
'{
  ".properties.backup_options": {
    "value": $backup_options
  }
}
+
if $backup_options == "enable" then
{
  ".properties.backup_options.enable.cron_schedule": {
    "value": ( $backup_options_enable_cron_schedule | gsub("\""; "") )
  },
  ".properties.backup_options.enable.backup_all_masters": {
    "value": $backup_options_enable_backup_all_masters
  }
}
else .
end
+
{
  ".properties.backups": {
    "value": $backups
  }
}
+
if $backups == "enable" then
{
  ".properties.backups.enable.endpoint_url": {
    "value": $backups_enable_endpoint_url
  },
  ".properties.backups.enable.bucket_name": {
    "value": $backups_enable_bucket_name
  },
  ".properties.backups.enable.bucket_path": {
    "value": $backups_enable_bucket_path
  },
  ".properties.backups.enable.access_key_id": {
    "value": $backups_enable_access_key_id
  },
  ".properties.backups.enable.secret_access_key": {
    "value": {
      "secret": $backups_enable_secret_access_key
    }
  },
  ".properties.backups.enable.region": {
    "value": $backups_enable_region
  }
}
elif $backups == "azure" then
{
  ".properties.backups.azure.storage_account": {
    "value": $backups_azure_storage_account
  },
  ".properties.backups.azure.storage_access_key": {
    "value": {
      "secret": $backups_azure_storage_access_key
    }
  },
  ".properties.backups.azure.container": {
    "value": $backups_azure_container
  },
  ".properties.backups.azure.container_path": {
    "value": $backups_azure_container_path
  },
  ".properties.backups.azure.base_url": {
    "value": $backups_azure_base_url
  }
}
elif $backups == "gcs" then
{
  ".properties.backups.gcs.service_account_json": {
    "value": {
      "secret": $backups_gcs_service_account_json
    }
  },
  ".properties.backups.gcs.project_id": {
    "value": $backups_gcs_project_id
  },
  ".properties.backups.gcs.bucket_name": {
    "value": $backups_gcs_bucket_name
  }
}
elif $backups == "scp" then
{
  ".properties.backups.scp.user": {
    "value": $backups_scp_user
  },
  ".properties.backups.scp.server": {
    "value": $backups_scp_server
  },
  ".properties.backups.scp.destination": {
    "value": $backups_scp_destination
  },
  ".properties.backups.scp.scp_key": {
    "value": $backups_scp_scp_key
  },
  ".properties.backups.scp.port": {
    "value": $backups_scp_port
  }
}
else .
end
+
{
  ".properties.plan_collection": {
    "value": [$plan_collection]
  },
  ".properties.optional_protections": {
    "value": $optional_protections
  }
}
+
if $optional_protections == "enable" then
{
  ".properties.optional_protections.enable.recipient_email": {
    "value": $optional_protections_enable_recipient_email
  },
  ".properties.optional_protections.enable.prevent_auto_rejoin": {
    "value": $optional_protections_enable_prevent_auto_rejoin
  },
  ".properties.optional_protections.enable.replication_canary": {
    "value": $optional_protections_enable_replication_canary
  },
  ".properties.optional_protections.enable.notify_only": {
    "value": $optional_protections_enable_notify_only
  },
  ".properties.optional_protections.enable.canary_poll_frequency": {
    "value": $optional_protections_enable_canary_poll_frequency
  },
  ".properties.optional_protections.enable.canary_write_read_delay": {
    "value": $optional_protections_enable_canary_write_read_delay
  }
}
else .
end
+
{
  ".properties.innodb_flush_log_at_trx_commit": {
    "value": $innodb_flush_log_at_trx_commit
  },
  ".properties.server_activity_logging": {
    "value": $server_activity_logging
  }
}
+
if $server_activity_logging == "enable" then
{
  ".properties.server_activity_logging.enable.audit_logging_events": {
    "value": $server_activity_logging_enable_audit_logging_events
  },
  ".properties.server_activity_logging.enable.server_audit_excluded_users_csv": {
    "value": $server_activity_logging_enable_server_audit_excluded_users_csv
  }
}
else .
end
+
{
  ".properties.syslog": {
    "value": $syslog
  }
}
+
if $syslog == "enabled" then
{
  ".properties.syslog.enabled.address": {
    "value": $syslog_enabled_address
  },
  ".properties.syslog.enabled.port": {
    "value": $syslog_enabled_port
  },
  ".properties.syslog.enabled.protocol": {
    "value": $syslog_enabled_protocol
  }
}
else .
end
+
{
  ".properties.buffer_pool_size": {
    "value": $buffer_pool_size
  }
}
+
if $buffer_pool_size == "percent" then
{
  ".properties.buffer_pool_size.percent.buffer_pool_size_percent": {
    "value": $buffer_pool_size_percent_buffer_pool_size_percent
  }
}
elif $buffer_pool_size == "bytes" then
{
  ".properties.buffer_pool_size.bytes.buffer_pool_size_bytes": {
    "value": $buffer_pool_size_bytes_buffer_pool_size_bytes
  }
}
else .
end
+
{
  ".mysql.roadmin_password": {
    "value": {
      "secret": $mysql_roadmin_password
    }
  },
  ".mysql.skip_name_resolve": {
    "value": $mysql_skip_name_resolve
  },
  ".mysql.innodb_large_prefix_enabled": {
    "value": $mysql_innodb_large_prefix_enabled
  },
  ".mysql.mysql_start_timeout": {
    "value": $mysql_mysql_start_timeout
  },
  ".mysql.metrics_polling_frequency": {
    "value": $mysql_metrics_polling_frequency
  },
  ".mysql.cluster_probe_timeout": {
    "value": $mysql_cluster_probe_timeout
  },
  ".mysql.tmp_table_size": {
    "value": $mysql_tmp_table_size
  },
  ".mysql.table_open_cache": {
    "value": $mysql_table_open_cache
  },
  ".mysql.table_definition_cache": {
    "value": $mysql_table_definition_cache
  },
  ".mysql.max_connections": {
    "value": $mysql_max_connections
  },
  ".mysql.binlog_expire_days": {
    "value": $mysql_binlog_expire_days
  },
  ".mysql.cluster_name": {
    "value": $mysql_cluster_name
  },
  ".mysql.innodb_strict_mode": {
    "value": $mysql_innodb_strict_mode
  },
  ".mysql.cli_history": {
    "value": $mysql_cli_history
  },
  ".mysql.allow_remote_admin_access": {
    "value": $mysql_allow_remote_admin_access
  },
  ".mysql.allow_local_infile": {
    "value": $mysql_allow_local_infile
  },
  ".proxy.static_ips": {
    "value": $proxy_static_ips
  },
  ".proxy.shutdown_delay": {
    "value": $proxy_shutdown_delay
  },
  ".proxy.startup_delay": {
    "value": $proxy_startup_delay
  },
  ".cf-mysql-broker.quota_enforcer_pause": {
    "value": $cf_mysql_broker_quota_enforcer_pause
  },
  ".cf-mysql-broker.allow_table_locks": {
    "value": $cf_mysql_broker_allow_table_locks
  },
  ".cf-mysql-broker.bind_hostname": {
    "value": $cf_mysql_broker_bind_hostname
  }
}'
)

resources_config="{
  \"mysql\": {\"instances\": ${MYSQL_INSTANCES:-3}, \"instance_type\": { \"id\": \"${MYSQL_INSTANCE_TYPE:-large.disk}\"}, \"persistent_disk\": { \"size_mb\": \"${MYSQL_PERSISTENT_DISK_MB:-51200}\"}},
  \"backup-prepare\": {\"instances\": ${BACKUP_PREPARE_INSTANCES:-1}, \"instance_type\": { \"id\": \"${BACKUP_PREPARE_INSTANCE_TYPE:-large.cpu}\"}, \"persistent_disk\": { \"size_mb\": \"${BACKUP_PREPARE_PERSISTENT_DISK_MB:-204800}\"}},
  \"proxy\": {\"instances\": ${PROXY_INSTANCES:-2}, \"instance_type\": { \"id\": \"${PROXY_INSTANCE_TYPE:-small.disk}\"}},
  \"monitoring\": {\"instances\": ${MONITORING_INSTANCES:-1}, \"instance_type\": { \"id\": \"${MONITORING_INSTANCE_TYPE:-micro}\"}},
  \"cf-mysql-broker\": {\"instances\": ${CF_MYSQL_BROKER_INSTANCES:-2}, \"instance_type\": { \"id\": \"${CF_MYSQL_BROKER_INSTANCE_TYPE:-small.disk}\"}}
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
