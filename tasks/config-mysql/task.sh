#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

PRODUCT_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg backup_options "$BACKUP_OPTIONS" \
    --arg backup_options_cron_schedule "$BACKUP_OPTIONS_CRON_SCHEDULE" \
    --argjson backup_options_backup_all_masters $BACKUP_OPTIONS_BACKUP_ALL_MASTERS \
    --arg backups "$BACKUPS" \
    --arg backups_s3_endpoint_url "$BACKUPS_S3_ENDPOINT_URL" \
    --arg backups_s3_bucket_name "$BACKUPS_S3_BUCKET_NAME" \
    --arg backups_s3_bucket_path "$BACKUPS_S3_BUCKET_PATH" \
    --arg backups_s3_access_key_id "$BACKUPS_S3_ACCESS_KEY_ID" \
    --arg backups_s3_secret_access_key "$BACKUPS_S3_SECRET_ACCESS_KEY" \
    --arg backups_s3_region "$BACKUPS_S3_REGION" \
    --arg backups_azure_storage_account "$BACKUPS_AZURE_STORAGE_ACCOUNT" \
    --arg backups_azure_storage_access_key "$BACKUPS_AZURE_STORAGE_ACCESS_KEY" \
    --arg backup_options_backup_all_masters "$BACKUP_OPTIONS_BACKUP_ALL_MASTERS" \
    --arg backups_azure_container "$BACKUPS_AZURE_CONTAINER" \
    --arg backups_azure_container_path "$BACKUPS_AZURE_CONTAINER_PATH" \
    --arg backups_azure_base_url "$BACKUPS_AZURE_BASE_URL" \
    --arg backups_gcs_service_account_json "$BACKUPS_GCS_SERVICE_ACCOUNT_JSON" \
    --arg backups_gcs_project_id "$BACKUPS_GCS_PROJECT_ID" \
    --arg backups_gcs_bucket_name "$BACKUPS_GCS_BUCKET_NAME" \
    --arg backups_scp_user "$BACKUPS_SCP_USER" \
    --arg backups_scp_server "$BACKUPS_SCP_SERVER" \
    --arg backups_scp_destination "$BACKUPS_SCP_DESTINATION" \
    --arg backups_scp_scp_key "$BACKUPS_SCP_SCP_KEY" \
    --argjson backups_scp_port $BACKUPS_SCP_PORT \
    --arg plan_collection_name "$PLAN_COLLECTION_NAME" \
    --arg plan_collection_description "$PLAN_COLLECTION_DESCRIPTION" \
    --argjson plan_collection_max_storage_mb $PLAN_COLLECTION_MAX_STORAGE_MB \
    --argjson plan_collection_max_user_connections $PLAN_COLLECTION_MAX_USER_CONNECTIONS \
    --argjson plan_collection_private $PLAN_COLLECTION_PRIVATE \
    --arg optional_protections "$OPTIONAL_PROTECTIONS" \
    --arg optional_protections_recipient_email "$OPTIONAL_PROTECTIONS_RECIPIENT_EMAIL" \
    --argjson optional_protections_prevent_auto_rejoin "$OPTIONAL_PROTECTIONS_PREVENT_AUTO_REJOIN" \
    --argjson optional_protections_replication_canary "$OPTIONAL_PROTECTIONS_REPLICATION_CANARY" \
    --argjson optional_protections_notify_only "$OPTIONAL_PROTECTIONS_NOTIFY_ONLY" \
    --argjson optional_protections_canary_poll_frequency "$OPTIONAL_PROTECTIONS_CANARY_POLL_FREQUENCY" \
    --argjson optional_protections_canary_write_read_delay "$OPTIONAL_PROTECTIONS_CANARY_WRITE_READ_DELAY" \
    --arg innodb_flush_log_at_trx_commit "$INNODB_FLUSH_LOG_AT_TRX_COMMIT" \
    --arg server_activity_logging "$SERVER_ACTIVITY_LOGGING" \
    --arg audit_logging_events "$AUDIT_LOGGING_EVENTS" \
    --arg server_audit_excluded_users_csv "$SERVER_AUDIT_EXCLUDED_USERS_CSV" \
    --arg syslog "$SYSLOG" \
    --arg syslog_address "$SYSLOG_ADDRESS" \
    --argjson syslog_port "$SYSLOG_PORT" \
    --arg buffer_pool_size "$BUFFER_POOL_SIZE" \
    --argjson buffer_pool_size_percent "$BUFFER_POOL_SIZE_PERCENT" \
    --arg buffer_pool_size_bytes "$BUFFER_POOL_SIZE_BYTES" \
    --arg mysql_roadmin_password "$MYSQL_ROADMIN_PASSWORD" \
    --argjson mysql_skip_name_resolve "$MYSQL_SKIP_NAME_RESOLVE" \
    --argjson mysql_innodb_large_prefix_enabled "$MYSQL_INNODB_LARGE_PREFIX_ENABLED" \
    --argjson mysql_mysql_start_timeout "$MYSQL_MYSQL_START_TIMEOUT" \
    --argjson mysql_metrics_polling_frequency "$MYSQL_METRICS_POLLING_FREQUENCY" \
    --argjson mysql_cluster_probe_timeout "$MYSQL_CLUSTER_PROBE_TIMEOUT" \
    --argjson mysql_tmp_table_size "$MYSQL_TMP_TABLE_SIZE" \
    --argjson mysql_table_open_cache "$MYSQL_TABLE_OPEN_CACHE" \
    --argjson mysql_table_definition_cache "$MYSQL_TABLE_DEFINITION_CACHE" \
    --argjson mysql_max_connections "$MYSQL_MAX_CONNECTIONS" \
    --argjson mysql_binlog_expire_days "$MYSQL_BINLOG_EXPIRE_DAYS" \
    --arg mysql_cluster_name "$MYSQL_CLUSTER_NAME" \
    --argjson mysql_innodb_strict_mode "$MYSQL_INNODB_STRICT_MODE" \
    --argjson mysql_cli_history "$MYSQL_CLI_HISTORY" \
    --argjson mysql_allow_remote_admin_access "$MYSQL_ALLOW_REMOTE_ADMIN_ACCESS" \
    --argjson mysql_allow_local_infile "$MYSQL_ALLOW_LOCAL_INFILE" \
    --arg proxy_static_ips "$PROXY_STATIC_IPS" \
    --argjson proxy_shutdown_delay "$PROXY_SHUTDOWN_DELAY" \
    --argjson proxy_startup_delay "$PROXY_STARTUP_DELAY" \
    --argjson cf_mysql_broker_quota_enforcer_pause "$CF_MYSQL_BROKER_QUOTA_ENFORCER_PAUSE" \
    --argjson cf_mysql_broker_allow_table_locks "$CF_MYSQL_BROKER_ALLOW_TABLE_LOCKS" \
    --arg cf_mysql_broker_bind_hostname "$CF_MYSQL_BROKER_BIND_HOSTNAME" \
    '
    . +
    {
      ".properties.backup_options": {
        "value": $backup_options
      }
    }
    +
    if $backup_options == "enable" then
    {
      ".properties.backup_options.enable.cron_schedule": {
        "value": $backup_options_cron_schedule
      },
      ".properties.backup_options.enable.backup_all_masters": {
        "value": $backup_options_backup_all_masters
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
        "value": $backups_s3_endpoint_url
      },
      ".properties.backups.enable.bucket_name": {
        "value": $backups_s3_bucket_name
      },
      ".properties.backups.enable.bucket_path": {
        "value": $backups_s3_bucket_path
      },
      ".properties.backups.enable.access_key_id": {
        "value": $backups_s3_access_key_id
      },
      ".properties.backups.enable.secret_access_key": {
        "value": {
          "secret": $backups_s3_secret_access_key
        }
      },
      ".properties.backups.enable.region": {
        "value": $backups_s3_region
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
        "value": [
          {
            "name": $plan_collection_name,
            "description": $plan_collection_description,
            "max_storage_mb": $plan_collection_max_storage_mb,
            "max_user_connections": $plan_collection_max_user_connections,
            "private": $plan_collection_private
          }
        ]
      },
      ".properties.optional_protections": {
        "value": $optional_protections
      }
    }
    +
    if $optional_protections == "enable" then
    {
      ".properties.optional_protections.enable.recipient_email": {
        "value": $optional_protections_recipient_email
      },
      ".properties.optional_protections.enable.prevent_auto_rejoin": {
        "value": $optional_protections_prevent_auto_rejoin
      },
      ".properties.optional_protections.enable.replication_canary": {
        "value": $optional_protections_replication_canary
      },
      ".properties.optional_protections.enable.notify_only": {
        "value": $optional_protections_notify_only
      },
      ".properties.optional_protections.enable.canary_poll_frequency": {
        "value": $optional_protections_canary_poll_frequency
      },
      ".properties.optional_protections.enable.canary_write_read_delay": {
        "value": $optional_protections_canary_write_read_delay
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
        "value": $audit_logging_events
      },
      ".properties.server_activity_logging.enable.server_audit_excluded_users_csv": {
        "value": $server_audit_excluded_users_csv
      },
      ".properties.syslog": {
        "value": $syslog
      }
    }
    else .
    end
    +
    if $syslog == "enabled" then
    {
      ".properties.syslog.enabled.address": {
        "value": $syslog_address
      },
      ".properties.syslog.enabled.port": {
        "value": $syslog_port
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
        "value": $buffer_pool_size_percent
      }
    }
    elif $buffer_pool_size == "bytes" then
    {
      ".properties.buffer_pool_size.bytes.buffer_pool_size_bytes": {
        "value": $buffer_pool_size_bytes
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
    --arg mysql_server_instance_type "$MYSQL_SERVER_INSTANCE_TYPE" \
    --argjson mysql_server_instances $MYSQL_SERVER_INSTANCES \
    --arg mysql_persistent_disk_mb "$MYSQL_PERSISTENT_DISK_MB" \
    --arg backup_prepare_instance_type "$BACKUP_PREPARE_INSTANCE_TYPE" \
    --argjson backup_prepare_instances $BACKUP_PREPARE_INSTANCES \
    --arg backup_prepare_persistent_disk_mb "$BACKUP_PREPARE_PERSISTENT_DISK_MB" \
    --arg mysql_proxy_instance_type "$MYSQL_PROXY_INSTANCE_TYPE" \
    --argjson mysql_proxy_instances $MYSQL_PROXY_INSTANCES \
    --arg monitoring_instance_type "$MONITORING_INSTANCE_TYPE" \
    --argjson monitoring_instances $MONITORING_INSTANCES \
    --arg mysql_broker_instance_type "$MYSQL_BROKER_INSTANCE_TYPE" \
    --argjson mysql_broker_instances $MYSQL_BROKER_INSTANCES \
    '. +
    {
      "mysql": {
        "instance_type": {"id": $mysql_server_instance_type},
        "instances" : $mysql_server_instances,
        "persistent_disk_mb": $mysql_persistent_disk_mb
      },
      "backup-prepare": {
        "instance_type": {"id": $backup_prepare_instance_type},
        "instances" : $backup_prepare_instances,
        "persistent_disk_mb": $backup_prepare_persistent_disk_mb
      },
      "proxy": {
        "instance_type": {"id": $mysql_proxy_instance_type},
        "instances" : $mysql_proxy_instances
      },
      "monitoring": {
        "instance_type": {"id": $monitoring_instance_type},
        "instances" : $monitoring_instances
      },
      "cf-mysql-broker": {
        "instance_type": {"id": $mysql_broker_instance_type},
        "instances" : $mysql_broker_instances
      }
    }
    '
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$PRODUCT_PROPERTIES" -pn "$PRODUCT_NETWORK" -pr "$PRODUCT_RESOURCE"
