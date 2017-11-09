#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PRODUCT_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg syslog_selector "$SYSLOG_SELECTOR" \
    --arg syslog_address "$SYSLOG_ADDRESS" \
    --argjson syslog_port "$SYSLOG_PORT" \
    --arg syslog_transport "$SYSLOG_TRANSPORT" \
    --arg syslog_format "$SYSLOG_FORMAT" \
    --arg syslog_permitted_peer "$SYSLOG_PERMITTED_PEER" \
    --arg syslog_ca_cert "$SYSLOG_CA_CERT" \
    --argjson metrics_polling_interval "$METRICS_POLLING_INTERVAL" \
    --arg small_plan_selector "$SMALL_PLAN_SELECTOR" \
    --arg small_plan_selector_name "$SMALL_PLAN_SELECTOR_NAME" \
    --arg small_plan_selector_description "$SMALL_PLAN_SELECTOR_DESCRIPTION" \
    --arg small_plan_selector_cf_service_access "$SMALL_PLAN_SELECTOR_CF_SERVICE_ACCESS" \
    --arg small_plan_selector_az_single_select "$SMALL_PLAN_SELECTOR_AZ_SINGLE_SELECT" \
    --arg small_plan_selector_vm_type "$SMALL_PLAN_SELECTOR_VM_TYPE" \
    --arg small_plan_selector_disk_size "$SMALL_PLAN_SELECTOR_DISK_SIZE" \
    --argjson small_plan_selector_timeout "$SMALL_PLAN_SELECTOR_TIMEOUT" \
    --argjson small_plan_selector_tcp_keepalive "$SMALL_PLAN_SELECTOR_TCP_KEEPALIVE" \
    --argjson small_plan_selector_maxclients "$SMALL_PLAN_SELECTOR_MAXCLIENTS" \
    --argjson small_plan_selector_lua_scripting "$SMALL_PLAN_SELECTOR_LUA_SCRIPTING" \
    --argjson small_plan_selector_instance_limit "$SMALL_PLAN_SELECTOR_INSTANCE_LIMIT" \
    --arg medium_plan_selector "$MEDIUM_PLAN_SELECTOR" \
    --arg medium_plan_selector_name "$MEDIUM_PLAN_SELECTOR_NAME" \
    --arg medium_plan_selector_description "$MEDIUM_PLAN_SELECTOR_DESCRIPTION" \
    --arg medium_plan_selector_cf_service_access "$MEDIUM_PLAN_SELECTOR_CF_SERVICE_ACCESS" \
    --arg medium_plan_selector_az_single_select "$MEDIUM_PLAN_SELECTOR_AZ_SINGLE_SELECT" \
    --arg medium_plan_selector_vm_type "$MEDIUM_PLAN_SELECTOR_VM_TYPE" \
    --arg medium_plan_selector_disk_size "$MEDIUM_PLAN_SELECTOR_DISK_SIZE" \
    --argjson medium_plan_selector_timeout "$MEDIUM_PLAN_SELECTOR_TIMEOUT" \
    --argjson medium_plan_selector_tcp_keepalive "$MEDIUM_PLAN_SELECTOR_TCP_KEEPALIVE" \
    --argjson medium_plan_selector_maxclients "$MEDIUM_PLAN_SELECTOR_MAXCLIENTS" \
    --argjson medium_plan_selector_lua_scripting "$MEDIUM_PLAN_SELECTOR_LUA_SCRIPTING" \
    --argjson medium_plan_selector_instance_limit "$MEDIUM_PLAN_SELECTOR_INSTANCE_LIMIT" \
    --arg large_plan_selector "$LARGE_PLAN_SELECTOR" \
    --arg large_plan_selector_name "$LARGE_PLAN_SELECTOR_NAME" \
    --arg large_plan_selector_description "$LARGE_PLAN_SELECTOR_DESCRIPTION" \
    --arg large_plan_selector_cf_service_access "$LARGE_PLAN_SELECTOR_CF_SERVICE_ACCESS" \
    --arg large_plan_selector_az_single_select "$LARGE_PLAN_SELECTOR_AZ_SINGLE_SELECT" \
    --arg large_plan_selector_vm_type "$LARGE_PLAN_SELECTOR_VM_TYPE" \
    --arg large_plan_selector_disk_size "$LARGE_PLAN_SELECTOR_DISK_SIZE" \
    --argjson large_plan_selector_timeout "$LARGE_PLAN_SELECTOR_TIMEOUT" \
    --argjson large_plan_selector_tcp_keepalive "$LARGE_PLAN_SELECTOR_TCP_KEEPALIVE" \
    --argjson large_plan_selector_maxclients "$LARGE_PLAN_SELECTOR_MAXCLIENTS" \
    --argjson large_plan_selector_lua_scripting "$LARGE_PLAN_SELECTOR_LUA_SCRIPTING" \
    --argjson large_plan_selector_instance_limit "$LARGE_PLAN_SELECTOR_INSTANCE_LIMIT" \
    --arg backups_selector "$BACKUPS_SELECTOR" \
    --arg backups_selector_s3_access_key_id "$BACKUPS_SELECTOR_S3_ACCESS_KEY_ID" \
    --arg backups_selector_s3_secret_access_key "$BACKUPS_SELECTOR_S3_SECRET_ACCESS_KEY" \
    --arg backups_selector_s3_endpoint_url "$BACKUPS_SELECTOR_S3_ENDPOINT_URL" \
    --arg backups_selector_s3_region "$BACKUPS_SELECTOR_S3_REGION" \
    --arg backups_selector_s3_signature_version "$BACKUPS_SELECTOR_S3_SIGNATURE_VERSION" \
    --arg backups_selector_s3_bucket_name "$BACKUPS_SELECTOR_S3_BUCKET_NAME" \
    --arg backups_selector_s3_path "$BACKUPS_SELECTOR_S3_PATH" \
    --arg backups_selector_s3_cron_schedule "$BACKUPS_SELECTOR_S3_CRON_SCHEDULE" \
    --argjson backups_selector_s3_bg_save_timeout "$BACKUPS_SELECTOR_S3_BG_SAVE_TIMEOUT" \
    --arg backups_selector_scp_server "$BACKUPS_SELECTOR_SCP_SERVER" \
    --arg backups_selector_scp_user "$BACKUPS_SELECTOR_SCP_USER" \
    --arg backups_selector_scp_key "$BACKUPS_SELECTOR_SCP_KEY" \
    --arg backups_selector_scp_path "$BACKUPS_SELECTOR_SCP_PATH" \
    --argjson backups_selector_scp_port "$BACKUPS_SELECTOR_SCP_PORT" \
    --arg backups_selector_scp_cron_schedule "$BACKUPS_SELECTOR_SCP_CRON_SCHEDULE" \
    --argjson backups_selector_scp_bg_save_timeout "$BACKUPS_SELECTOR_SCP_BG_SAVE_TIMEOUT" \
    --arg backups_selector_scp_fingerprint "$BACKUPS_SELECTOR_SCP_FINGERPRINT" \
    --arg backups_selector_azure_account "$BACKUPS_SELECTOR_AZURE_ACCOUNT" \
    --arg backups_selector_azure_storage_access_key "$BACKUPS_SELECTOR_AZURE_STORAGE_ACCESS_KEY" \
    --arg backups_selector_azure_path "$BACKUPS_SELECTOR_AZURE_PATH" \
    --arg backups_selector_azure_cron_schedule "$BACKUPS_SELECTOR_AZURE_CRON_SCHEDULE" \
    --argjson backups_selector_azure_bg_save_timeout "$BACKUPS_SELECTOR_AZURE_BG_SAVE_TIMEOUT" \
    --arg backups_selector_azure_container "$BACKUPS_SELECTOR_AZURE_CONTAINER" \
    --arg backups_selector_azure_blob_store_base_url "$BACKUPS_SELECTOR_AZURE_BLOB_STORE_BASE_URL" \
    --arg backups_selector_gcs_project_id "$BACKUPS_SELECTOR_GCS_PROJECT_ID" \
    --arg backups_selector_gcs_bucket_name "$BACKUPS_SELECTOR_GCS_BUCKET_NAME" \
    --arg backups_selector_gcs_service_account_json "$BACKUPS_SELECTOR_GCS_SERVICE_ACCOUNT_JSON" \
    --arg backups_selector_gcs_cron_schedule "$BACKUPS_SELECTOR_GCS_CRON_SCHEDULE" \
    --argjson backups_selector_gcs_bg_save_timeout "$BACKUPS_SELECTOR_GCS_BG_SAVE_TIMEOUT" \
    --arg redis_on_demand_broker_service_instance_limit "$REDIS_ON_DEMAND_BROKER_SERVICE_INSTANCE_LIMIT" \
    --arg redis_on_demand_broker_vm_extensions "$REDIS_ON_DEMAND_BROKER_VM_EXTENSIONS" \
    --argjson cf_redis_broker_service_instance_limit "$CF_REDIS_BROKER_SERVICE_INSTANCE_LIMIT" \
    --arg cf_redis_broker_redis_maxmemory "$CF_REDIS_BROKER_REDIS_MAXMEMORY" \
    '
    . +
    {
      ".properties.syslog_selector": {
        "value": $syslog_selector
      }
    }
    +
    if $syslog_selector == "Yes without encryption" then
    {
      ".properties.syslog_selector.active.syslog_address": {
        "value": $syslog_address
      },
      ".properties.syslog_selector.active.syslog_port": {
        "value": $syslog_port
      },
      ".properties.syslog_selector.active.syslog_transport": {
        "value": $syslog_transport
      },
      ".properties.syslog_selector.active.syslog_format": {
        "value": $syslog_format
      }
    }
    elif $syslog_selector == "Yes with TLS encryption" then
      ".properties.syslog_selector.active_with_tls.syslog_address": {
        "value": $syslog_address
      },
      ".properties.syslog_selector.active_with_tls.syslog_port": {
        "value": $syslog_port
      },
      ".properties.syslog_selector.active_with_tls.syslog_format": {
        "value": $syslog_format
      },
      ".properties.syslog_selector.active_with_tls.syslog_permitted_peer": {
        "value": $syslog_permitted_peer
      },
      ".properties.syslog_selector.active_with_tls.syslog_ca_cert": {
        "value": $syslog_ca_cert
      }
    }
    else .
    end
    +
    {
      ".properties.metrics_polling_interval": {
        "value": $metrics_polling_interval
      },
      ".properties.small_plan_selector": {
        "value": $small_plan_selector
      }
    }
    +
    if $small_plan_selector == "Plan Active" then
    {
      ".properties.small_plan_selector.active.name": {
        "value": $small_plan_selector_name
      },
      ".properties.small_plan_selector.active.description": {
        "value": $small_plan_selector_description
      },
      ".properties.small_plan_selector.active.cf_service_access": {
        "value": $small_plan_selector_cf_service_access
      },
      ".properties.small_plan_selector.active.az_single_select": {
        "value": $small_plan_selector_az_single_select
      },
      ".properties.small_plan_selector.active.vm_type": {
        "value": $small_plan_selector_vm_type
      },
      ".properties.small_plan_selector.active.disk_size": {
        "value": $small_plan_selector_disk_size
      },
      ".properties.small_plan_selector.active.timeout": {
        "value": $small_plan_selector_timeout
      },
      ".properties.small_plan_selector.active.tcp_keepalive": {
        "value": $small_plan_selector_tcp_keepalive
      },
      ".properties.small_plan_selector.active.maxclients": {
        "value": $small_plan_selector_maxclients
      },
      ".properties.small_plan_selector.active.lua_scripting": {
        "value": $small_plan_selector_lua_scripting
      },
      ".properties.small_plan_selector.active.instance_limit": {
        "value": $small_plan_selector_instance_limit
      }
    }
    else .
    end
    +
    {
      ".properties.medium_plan_selector": {
        "value": $medium_plan_selector
      }
    }
    +
    if $medium_plan_selector == "Plan Active" then
    {
      ".properties.medium_plan_selector.active.name": {
        "value": $medium_plan_selector_name
      },
      ".properties.medium_plan_selector.active.description": {
        "value": $medium_plan_selector_description
      },
      ".properties.medium_plan_selector.active.cf_service_access": {
        "value": $medium_plan_selector_cf_service_access
      },
      ".properties.medium_plan_selector.active.az_single_select": {
        "value": $medium_plan_selector_az_single_select
      },
      ".properties.medium_plan_selector.active.vm_type": {
        "value": $medium_plan_selector_vm_type
      },
      ".properties.medium_plan_selector.active.disk_size": {
        "value": $medium_plan_selector_disk_size
      },
      ".properties.medium_plan_selector.active.timeout": {
        "value": $medium_plan_selector_timeout
      },
      ".properties.medium_plan_selector.active.tcp_keepalive": {
        "value": $medium_plan_selector_tcp_keepalive
      },
      ".properties.medium_plan_selector.active.maxclients": {
        "value": $medium_plan_selector_maxclients
      },
      ".properties.medium_plan_selector.active.lua_scripting": {
        "value": $medium_plan_selector_lua_scripting
      },
      ".properties.medium_plan_selector.active.instance_limit": {
        "value": $medium_plan_selector_instance_limit
      }
    }
    else .
    end
    +
    {
      ".properties.large_plan_selector": {
        "value": $large_plan_selector
      }
    }
    +
    if $large_plan_selector == "Plan Active" then
    {
      ".properties.large_plan_selector.active.name": {
        "value": $large_plan_selector_name
      },
      ".properties.large_plan_selector.active.description": {
        "value": $large_plan_selector_description
      },
      ".properties.large_plan_selector.active.cf_service_access": {
        "value": $large_plan_selector_cf_service_access
      },
      ".properties.large_plan_selector.active.az_single_select": {
        "value": $large_plan_selector_az_single_select
      },
      ".properties.large_plan_selector.active.vm_type": {
        "value": $large_plan_selector_vm_type
      },
      ".properties.large_plan_selector.active.disk_size": {
        "value": $large_plan_selector_disk_size
      },
      ".properties.large_plan_selector.active.timeout": {
        "value": $large_plan_selector_timeout
      },
      ".properties.large_plan_selector.active.tcp_keepalive": {
        "value": $large_plan_selector_tcp_keepalive
      },
      ".properties.large_plan_selector.active.maxclients": {
        "value": $large_plan_selector_maxclients
      },
      ".properties.large_plan_selector.active.lua_scripting": {
        "value": $large_plan_selector_lua_scripting
      },
      ".properties.large_plan_selector.active.instance_limit": {
        "value": $large_plan_selector_instance_limit
      }
    }
    else .
    end
    +
    {
      ".properties.backups_selector": {
        "value": $backups_selector
      }
    }
    +
    if $backups_selector == "s3" then
    {
      ".properties.backups_selector.s3.access_key_id": {
        "value": $backups_selector_s3_access_key_id
      },
      ".properties.backups_selector.s3.secret_access_key": {
        "value": $backups_selector_s3_secret_access_key
      },
      ".properties.backups_selector.s3.endpoint_url": {
        "value": $backups_selector_s3_endpoint_url
      },
      ".properties.backups_selector.s3.region": {
        "value": $backups_selector_s3_region
      },
      ".properties.backups_selector.s3.signature_version": {
        "value": $backups_selector_s3_signature_version
      },
      ".properties.backups_selector.s3.bucket_name": {
        "value": $backups_selector_s3_bucket_name
      },
      ".properties.backups_selector.s3.path": {
        "value": $backups_selector_s3_path
      },
      ".properties.backups_selector.s3.cron_schedule": {
        "value": $backups_selector_s3_cron_schedule
      },
      ".properties.backups_selector.s3.bg_save_timeout": {
        "value": $backups_selector_s3_bg_save_timeout
      }
    }
    elif $backups_selector == "scp" then
    {
      ".properties.backups_selector.scp.server": {
        "value": $backups_selector_scp_server
      },
      ".properties.backups_selector.scp.user": {
        "value": $backups_selector_scp_user
      },
      ".properties.backups_selector.scp.key": {
        "value": $backups_selector_scp_key
      },
      ".properties.backups_selector.scp.path": {
        "value": $backups_selector_scp_path
      },
      ".properties.backups_selector.scp.port": {
        "value": $backups_selector_scp_port
      },
      ".properties.backups_selector.scp.cron_schedule": {
        "value": $backups_selector_scp_cron_schedule
      },
      ".properties.backups_selector.scp.bg_save_timeout": {
        "value": $backups_selector_scp_bg_save_timeout
      },
      ".properties.backups_selector.scp.fingerprint": {
        "value": $backups_selector_scp_fingerprint
      }
    }
    elif $backups_selector == "azure" then
    {
      ".properties.backups_selector.azure.account": {
        "value": $backups_selector_azure_account
      },
      ".properties.backups_selector.azure.storage_access_key": {
        "value": $backups_selector_azure_storage_access_key
      },
      ".properties.backups_selector.azure.path": {
        "value": $backups_selector_azure_path
      },
      ".properties.backups_selector.azure.cron_schedule": {
        "value": $backups_selector_azure_cron_schedule
      },
      ".properties.backups_selector.azure.bg_save_timeout": {
        "value": $backups_selector_azure_bg_save_timeout
      },
      ".properties.backups_selector.azure.container": {
        "value": $backups_selector_azure_container
      },
      ".properties.backups_selector.azure.blob_store_base_url": {
        "value": $backups_selector_azure_blob_store_base_url
      }
    }
    elif $backups_selector == "gcs" then
    {
      ".properties.backups_selector.gcs.project_id": {
        "value": $backups_selector_gcs_project_id
      },
      ".properties.backups_selector.gcs.bucket_name": {
        "value": $backups_selector_gcs_bucket_name
      },
      ".properties.backups_selector.gcs.service_account_json": {
        "value": $backups_selector_gcs_service_account_json
      },
      ".properties.backups_selector.gcs.cron_schedule": {
        "value": $backups_selector_gcs_cron_schedule
      },
      ".properties.backups_selector.gcs.bg_save_timeout": {
        "value": $backups_selector_gcs_bg_save_timeout
      }
    }
    else .
    end
    +
    {
      ".redis-on-demand-broker.service_instance_limit": {
        "value": $redis_on_demand_broker_service_instance_limit
      },
      ".redis-on-demand-broker.vm_extensions": {
        "value": $redis_on_demand_broker_vm_extensions
      },
      ".cf-redis-broker.service_instance_limit": {
        "value": $cf_redis_broker_service_instance_limit
      },
      ".cf-redis-broker.redis_maxmemory": {
        "value": $cf_redis_broker_redis_maxmemory
      }
    }'
)

PRODUCT_NETWORK_CONFIG=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg SINGLETON_JOB_AZ "$SINGLETON_JOB_AZ" \
    --arg BALANCE_JOB_AZS "$BALANCE_JOB_AZS" \
    --arg NETWORK_NAME "$NETWORK_NAME" \
    --arg SERVICES_NETWORK_NAME "$SERVICES_NETWORK_NAME" \
    '. +
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
        "name": "$SERVICES_NETWORK_NAME"
      }
    }
    '
)

PRODUCT_RESOURCE_CONFIG=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg REDIS_ON_DEMAND_BROKER_INSTANCE_TYPE "$REDIS_ON_DEMAND_BROKER_INSTANCE_TYPE" \
    --argjson REDIS_ON_DEMAND_BROKER_INSTANCES "$REDIS_ON_DEMAND_BROKER_INSTANCES" \
    --arg REDIS_ON_DEMAND_BROKER_DISK_SIZE "$REDIS_ON_DEMAND_BROKER_DISK_SIZE" \
    --arg CF_REDIS_BROKER_INSTANCE_TYPE "$CF_REDIS_BROKER_INSTANCE_TYPE" \
    --argjson CF_REDIS_BROKER_INSTANCES "$CF_REDIS_BROKER_INSTANCES" \
    --arg CF_REDIS_BROKER_DISK_SIZE "$CF_REDIS_BROKER_DISK_SIZE" \
    --arg DEDICATED_NODE_INSTANCE_TYPE "$DEDICATED_NODE_INSTANCE_TYPE" \
    --argjson DEDICATED_NODE_INSTANCES "$DEDICATED_NODE_INSTANCES" \
    --arg DEDICATED_NODE_DISK_SIZE "$DEDICATED_NODE_DISK_SIZE" \
    '. +
    {
      "redis-on-demand-broker": {
        "instance_type": {"id": $REDIS_ON_DEMAND_BROKER_INSTANCE_TYPE},
        "instances": $REDIS_ON_DEMAND_BROKER_INSTANCES,
        "persistent_disk": {"size_mb":"$REDIS_ON_DEMAND_BROKER_DISK_SIZE"}
      },
      "cf-redis-broker": {
        "instance_type": {"id": $CF_REDIS_BROKER_INSTANCE_TYPE},
        "instances": $CF_REDIS_BROKER_INSTANCES,
        "persistent_disk": {"size_mb":"$CF_REDIS_BROKER_DISK_SIZE"}
      },
      "dedicated-node": {
        "instance_type": {"id": $DEDICATED_NODE_INSTANCE_TYPE},
        "instances": $DEDICATED_NODE_INSTANCES,
        "persistent_disk": {"size_mb":"$DEDICATED_NODE_DISK_SIZE"}
      }
    }'
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG" -p "$PRODUCT_PROPERTIES" -pr "$PRODUCT_RESOURCE_CONFIG"
