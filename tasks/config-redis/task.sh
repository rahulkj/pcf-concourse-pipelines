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
  --arg cf_redis_broker_redis_maxmemory "${CF_REDIS_BROKER_REDIS_MAXMEMORY:-"1024MB"}" \
  --arg cf_redis_broker_service_instance_limit "${CF_REDIS_BROKER_SERVICE_INSTANCE_LIMIT:-5}" \
  --arg backups_selector "${BACKUPS_SELECTOR:-"No Backups"}" \
  --arg backups_selector_azure_account "${BACKUPS_SELECTOR_AZURE_ACCOUNT:-''}" \
  --arg backups_selector_azure_bg_save_timeout "${BACKUPS_SELECTOR_AZURE_BG_SAVE_TIMEOUT:-10}" \
  --arg backups_selector_azure_blob_store_base_url "${BACKUPS_SELECTOR_AZURE_BLOB_STORE_BASE_URL:-''}" \
  --arg backups_selector_azure_container "${BACKUPS_SELECTOR_AZURE_CONTAINER:-''}" \
  --arg backups_selector_azure_cron_schedule "${BACKUPS_SELECTOR_AZURE_CRON_SCHEDULE:-"0 0 * * *"}" \
  --arg backups_selector_azure_path "${BACKUPS_SELECTOR_AZURE_PATH:-''}" \
  --arg backups_selector_azure_storage_access_key "${BACKUPS_SELECTOR_AZURE_STORAGE_ACCESS_KEY:-''}" \
  --arg backups_selector_gcs_bg_save_timeout "${BACKUPS_SELECTOR_GCS_BG_SAVE_TIMEOUT:-10}" \
  --arg backups_selector_gcs_bucket_name "${BACKUPS_SELECTOR_GCS_BUCKET_NAME:-''}" \
  --arg backups_selector_gcs_cron_schedule "${BACKUPS_SELECTOR_GCS_CRON_SCHEDULE:-"0 0 * * *"}" \
  --arg backups_selector_gcs_project_id "${BACKUPS_SELECTOR_GCS_PROJECT_ID:-''}" \
  --arg backups_selector_gcs_service_account_json "${BACKUPS_SELECTOR_GCS_SERVICE_ACCOUNT_JSON:-'{}'}" \
  --arg backups_selector_s3_access_key_id "${BACKUPS_SELECTOR_S3_ACCESS_KEY_ID:-''}" \
  --arg backups_selector_s3_bg_save_timeout "${BACKUPS_SELECTOR_S3_BG_SAVE_TIMEOUT:-10}" \
  --arg backups_selector_s3_bucket_name "${BACKUPS_SELECTOR_S3_BUCKET_NAME:-''}" \
  --arg backups_selector_s3_cron_schedule "${BACKUPS_SELECTOR_S3_CRON_SCHEDULE:-"0 0 * * *"}" \
  --arg backups_selector_s3_endpoint_url "${BACKUPS_SELECTOR_S3_ENDPOINT_URL:-''}" \
  --arg backups_selector_s3_path "${BACKUPS_SELECTOR_S3_PATH:-''}" \
  --arg backups_selector_s3_region "${BACKUPS_SELECTOR_S3_REGION:-''}" \
  --arg backups_selector_s3_secret_access_key "${BACKUPS_SELECTOR_S3_SECRET_ACCESS_KEY:-''}" \
  --arg backups_selector_s3_signature_version "${BACKUPS_SELECTOR_S3_SIGNATURE_VERSION:-"4"}" \
  --arg backups_selector_scp_bg_save_timeout "${BACKUPS_SELECTOR_SCP_BG_SAVE_TIMEOUT:-10}" \
  --arg backups_selector_scp_cron_schedule "${BACKUPS_SELECTOR_SCP_CRON_SCHEDULE:-"0 0 * * *"}" \
  --arg backups_selector_scp_fingerprint "${BACKUPS_SELECTOR_SCP_FINGERPRINT:-''}" \
  --arg backups_selector_scp_key "${BACKUPS_SELECTOR_SCP_KEY:-''}" \
  --arg backups_selector_scp_path "${BACKUPS_SELECTOR_SCP_PATH:-''}" \
  --arg backups_selector_scp_port "${BACKUPS_SELECTOR_SCP_PORT:-22}" \
  --arg backups_selector_scp_server "${BACKUPS_SELECTOR_SCP_SERVER:-''}" \
  --arg backups_selector_scp_user "${BACKUPS_SELECTOR_SCP_USER:-''}" \
  --arg large_plan_selector "${LARGE_PLAN_SELECTOR:-"Plan Inactive"}" \
  --arg large_plan_selector_active_az_single_select "${LARGE_PLAN_SELECTOR_ACTIVE_AZ_SINGLE_SELECT}" \
  --arg large_plan_selector_active_cf_service_access "${LARGE_PLAN_SELECTOR_ACTIVE_CF_SERVICE_ACCESS:-"enable"}" \
  --arg large_plan_selector_active_description "${LARGE_PLAN_SELECTOR_ACTIVE_DESCRIPTION:-"This plan provides a large dedicated Redis instance, tailored for caching use-cases with persistence to disk enabled"}" \
  --arg large_plan_selector_active_disk_size "${LARGE_PLAN_SELECTOR_ACTIVE_DISK_SIZE:-'20480'}" \
  --arg large_plan_selector_active_instance_limit "${LARGE_PLAN_SELECTOR_ACTIVE_INSTANCE_LIMIT:-20}" \
  --arg large_plan_selector_active_lua_scripting "${LARGE_PLAN_SELECTOR_ACTIVE_LUA_SCRIPTING:-false}" \
  --arg large_plan_selector_active_maxclients "${LARGE_PLAN_SELECTOR_ACTIVE_MAXCLIENTS:-10000}" \
  --arg large_plan_selector_active_name "${LARGE_PLAN_SELECTOR_ACTIVE_NAME:-"cache-large"}" \
  --arg large_plan_selector_active_tcp_keepalive "${LARGE_PLAN_SELECTOR_ACTIVE_TCP_KEEPALIVE:-60}" \
  --arg large_plan_selector_active_timeout "${LARGE_PLAN_SELECTOR_ACTIVE_TIMEOUT:-3600}" \
  --arg large_plan_selector_active_vm_type "${LARGE_PLAN_SELECTOR_ACTIVE_VM_TYPE:-'medium.mem'}" \
  --arg medium_plan_selector "${MEDIUM_PLAN_SELECTOR:-"Plan Inactive"}" \
  --arg medium_plan_selector_active_az_single_select "${MEDIUM_PLAN_SELECTOR_ACTIVE_AZ_SINGLE_SELECT}" \
  --arg medium_plan_selector_active_cf_service_access "${MEDIUM_PLAN_SELECTOR_ACTIVE_CF_SERVICE_ACCESS:-"enable"}" \
  --arg medium_plan_selector_active_description "${MEDIUM_PLAN_SELECTOR_ACTIVE_DESCRIPTION:-"This plan provides a medium dedicated Redis instance, tailored for caching use-cases with persistence to disk enabled"}" \
  --arg medium_plan_selector_active_disk_size "${MEDIUM_PLAN_SELECTOR_ACTIVE_DISK_SIZE:-'10240'}" \
  --arg medium_plan_selector_active_instance_limit "${MEDIUM_PLAN_SELECTOR_ACTIVE_INSTANCE_LIMIT:-20}" \
  --arg medium_plan_selector_active_lua_scripting "${MEDIUM_PLAN_SELECTOR_ACTIVE_LUA_SCRIPTING:-false}" \
  --arg medium_plan_selector_active_maxclients "${MEDIUM_PLAN_SELECTOR_ACTIVE_MAXCLIENTS:-5000}" \
  --arg medium_plan_selector_active_name "${MEDIUM_PLAN_SELECTOR_ACTIVE_NAME:-"cache-medium"}" \
  --arg medium_plan_selector_active_tcp_keepalive "${MEDIUM_PLAN_SELECTOR_ACTIVE_TCP_KEEPALIVE:-60}" \
  --arg medium_plan_selector_active_timeout "${MEDIUM_PLAN_SELECTOR_ACTIVE_TIMEOUT:-3600}" \
  --arg medium_plan_selector_active_vm_type "${MEDIUM_PLAN_SELECTOR_ACTIVE_VM_TYPE:-'small'}" \
  --arg metrics_polling_interval "${METRICS_POLLING_INTERVAL:-30}" \
  --arg small_plan_selector "${SMALL_PLAN_SELECTOR:-"Plan Active"}" \
  --arg small_plan_selector_active_az_single_select "${SMALL_PLAN_SELECTOR_ACTIVE_AZ_SINGLE_SELECT}" \
  --arg small_plan_selector_active_cf_service_access "${SMALL_PLAN_SELECTOR_ACTIVE_CF_SERVICE_ACCESS:-"enable"}" \
  --arg small_plan_selector_active_description "${SMALL_PLAN_SELECTOR_ACTIVE_DESCRIPTION:-"This plan provides a small dedicated Redis instance, tailored for caching use-cases with persistence to disk enabled"}" \
  --arg small_plan_selector_active_disk_size "${SMALL_PLAN_SELECTOR_ACTIVE_DISK_SIZE:-"5120"}" \
  --arg small_plan_selector_active_instance_limit "${SMALL_PLAN_SELECTOR_ACTIVE_INSTANCE_LIMIT:-20}" \
  --arg small_plan_selector_active_lua_scripting "${SMALL_PLAN_SELECTOR_ACTIVE_LUA_SCRIPTING:-false}" \
  --arg small_plan_selector_active_maxclients "${SMALL_PLAN_SELECTOR_ACTIVE_MAXCLIENTS:-1000}" \
  --arg small_plan_selector_active_name "${SMALL_PLAN_SELECTOR_ACTIVE_NAME:-"cache-small"}" \
  --arg small_plan_selector_active_tcp_keepalive "${SMALL_PLAN_SELECTOR_ACTIVE_TCP_KEEPALIVE:-60}" \
  --arg small_plan_selector_active_timeout "${SMALL_PLAN_SELECTOR_ACTIVE_TIMEOUT:-3600}" \
  --arg small_plan_selector_active_vm_type "${SMALL_PLAN_SELECTOR_ACTIVE_VM_TYPE:-"micro"}" \
  --arg syslog_selector "${SYSLOG_SELECTOR:-"Yes without encryption"}" \
  --arg syslog_selector_active_syslog_address "${SYSLOG_SELECTOR_ACTIVE_SYSLOG_ADDRESS:-"splunk.homelab.io"}" \
  --arg syslog_selector_active_syslog_format "${SYSLOG_SELECTOR_ACTIVE_SYSLOG_FORMAT:-"rfc5424"}" \
  --arg syslog_selector_active_syslog_port "${SYSLOG_SELECTOR_ACTIVE_SYSLOG_PORT:-5514}" \
  --arg syslog_selector_active_syslog_transport "${SYSLOG_SELECTOR_ACTIVE_SYSLOG_TRANSPORT:-"relp"}" \
  --arg syslog_selector_active_with_tls_syslog_address "${SYSLOG_SELECTOR_ACTIVE_WITH_TLS_SYSLOG_ADDRESS:-''}" \
  --arg syslog_selector_active_with_tls_syslog_ca_cert "${SYSLOG_SELECTOR_ACTIVE_WITH_TLS_SYSLOG_CA_CERT:-''}" \
  --arg syslog_selector_active_with_tls_syslog_format "${SYSLOG_SELECTOR_ACTIVE_WITH_TLS_SYSLOG_FORMAT:-"rfc5424"}" \
  --arg syslog_selector_active_with_tls_syslog_permitted_peer "${SYSLOG_SELECTOR_ACTIVE_WITH_TLS_SYSLOG_PERMITTED_PEER:-''}" \
  --arg syslog_selector_active_with_tls_syslog_port "${SYSLOG_SELECTOR_ACTIVE_WITH_TLS_SYSLOG_PORT:-''}" \
  --arg redis_on_demand_broker_service_instance_limit "${REDIS_ON_DEMAND_BROKER_SERVICE_INSTANCE_LIMIT:-20}" \
  --arg redis_on_demand_broker_vm_extensions "${REDIS_ON_DEMAND_BROKER_VM_EXTENSIONS}" \
'{
  ".properties.syslog_selector": {
    "value": $syslog_selector
  }
}
+
if $syslog_selector == "Yes without encryption" then
{
  ".properties.syslog_selector.active.syslog_address": {
    "value": $syslog_selector_active_syslog_address
  },
  ".properties.syslog_selector.active.syslog_port": {
    "value": $syslog_selector_active_syslog_port
  },
  ".properties.syslog_selector.active.syslog_transport": {
    "value": $syslog_selector_active_syslog_transport
  },
  ".properties.syslog_selector.active.syslog_format": {
    "value": $syslog_selector_active_syslog_format
  },
  ".properties.syslog_selector.active_with_tls.syslog_address": {
    "value": $syslog_selector_active_with_tls_syslog_address
  },
  ".properties.syslog_selector.active_with_tls.syslog_port": {
    "value": $syslog_selector_active_with_tls_syslog_port
  },
  ".properties.syslog_selector.active_with_tls.syslog_format": {
    "value": $syslog_selector_active_with_tls_syslog_format
  },
  ".properties.syslog_selector.active_with_tls.syslog_permitted_peer": {
    "value": $syslog_selector_active_with_tls_syslog_permitted_peer
  },
  ".properties.syslog_selector.active_with_tls.syslog_ca_cert": {
    "value": $syslog_selector_active_with_tls_syslog_ca_cert
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
    "value": $small_plan_selector_active_name
  },
  ".properties.small_plan_selector.active.description": {
    "value": $small_plan_selector_active_description
  },
  ".properties.small_plan_selector.active.cf_service_access": {
    "value": $small_plan_selector_active_cf_service_access
  },
  ".properties.small_plan_selector.active.az_single_select": {
    "value": $small_plan_selector_active_az_single_select
  },
  ".properties.small_plan_selector.active.vm_type": {
    "value": $small_plan_selector_active_vm_type
  },
  ".properties.small_plan_selector.active.disk_size": {
    "value": $small_plan_selector_active_disk_size
  },
  ".properties.small_plan_selector.active.timeout": {
    "value": $small_plan_selector_active_timeout
  },
  ".properties.small_plan_selector.active.tcp_keepalive": {
    "value": $small_plan_selector_active_tcp_keepalive
  },
  ".properties.small_plan_selector.active.maxclients": {
    "value": $small_plan_selector_active_maxclients
  },
  ".properties.small_plan_selector.active.lua_scripting": {
    "value": $small_plan_selector_active_lua_scripting
  },
  ".properties.small_plan_selector.active.instance_limit": {
    "value": $small_plan_selector_active_instance_limit
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
    "value": $medium_plan_selector_active_name
  },
  ".properties.medium_plan_selector.active.description": {
    "value": $medium_plan_selector_active_description
  },
  ".properties.medium_plan_selector.active.cf_service_access": {
    "value": $medium_plan_selector_active_cf_service_access
  },
  ".properties.medium_plan_selector.active.az_single_select": {
    "value": $medium_plan_selector_active_az_single_select
  },
  ".properties.medium_plan_selector.active.vm_type": {
    "value": $medium_plan_selector_active_vm_type
  },
  ".properties.medium_plan_selector.active.disk_size": {
    "value": $medium_plan_selector_active_disk_size
  },
  ".properties.medium_plan_selector.active.timeout": {
    "value": $medium_plan_selector_active_timeout
  },
  ".properties.medium_plan_selector.active.tcp_keepalive": {
    "value": $medium_plan_selector_active_tcp_keepalive
  },
  ".properties.medium_plan_selector.active.maxclients": {
    "value": $medium_plan_selector_active_maxclients
  },
  ".properties.medium_plan_selector.active.lua_scripting": {
    "value": $medium_plan_selector_active_lua_scripting
  },
  ".properties.medium_plan_selector.active.instance_limit": {
    "value": $medium_plan_selector_active_instance_limit
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
    "value": $large_plan_selector_active_name
  },
  ".properties.large_plan_selector.active.description": {
    "value": $large_plan_selector_active_description
  },
  ".properties.large_plan_selector.active.cf_service_access": {
    "value": $large_plan_selector_active_cf_service_access
  },
  ".properties.large_plan_selector.active.az_single_select": {
    "value": $large_plan_selector_active_az_single_select
  },
  ".properties.large_plan_selector.active.vm_type": {
    "value": $large_plan_selector_active_vm_type
  },
  ".properties.large_plan_selector.active.disk_size": {
    "value": $large_plan_selector_active_disk_size
  },
  ".properties.large_plan_selector.active.timeout": {
    "value": $large_plan_selector_active_timeout
  },
  ".properties.large_plan_selector.active.tcp_keepalive": {
    "value": $large_plan_selector_active_tcp_keepalive
  },
  ".properties.large_plan_selector.active.maxclients": {
    "value": $large_plan_selector_active_maxclients
  },
  ".properties.large_plan_selector.active.lua_scripting": {
    "value": $large_plan_selector_active_lua_scripting
  },
  ".properties.large_plan_selector.active.instance_limit": {
    "value": $large_plan_selector_active_instance_limit
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
if $backups_selector == "S3 Backups" then
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
elif $backups_selector == "SCP Backups" then
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
elif $backups_selector == "Azure Backups" then
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
elif $backups_selector == "Google Cloud Storage Backups" then
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

resources_config="{
  \"redis-on-demand-broker\": {\"instances\": ${REDIS_ON_DEMAND_BROKER_INSTANCES:-1}, \"instance_type\": { \"id\": \"${REDIS_ON_DEMAND_BROKER_INSTANCE_TYPE:-medium}\"}, \"persistent_disk\": { \"size_mb\": \"${REDIS_ON_DEMAND_BROKER_PERSISTENT_DISK_MB:-10240}\"}},
  \"dedicated-node\": {\"instances\": ${DEDICATED_NODE_INSTANCES:-5}, \"instance_type\": { \"id\": \"${DEDICATED_NODE_INSTANCE_TYPE:-micro.ram}\"}, \"persistent_disk\": { \"size_mb\": \"${DEDICATED_NODE_PERSISTENT_DISK_MB:-5120}\"}}
}"

network_config=$($JQ_CMD -n \
  --arg network_name "$NETWORK_NAME" \
  --arg other_azs "$OTHER_AZS" \
  --arg singleton_az "$SINGLETON_JOBS_AZ" \
  --arg service_network_name "$SERVICE_NETWORK_NAME" \
'
  {
    "network": {
      "name": $network_name
    },
    "other_availability_zones": ($other_azs | split(",") | map({name: .})),
    "singleton_availability_zone": {
      "name": $singleton_az
    },
    "service_network": {
      "name": $service_network_name
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
  --product-name p-redis \
  --product-network "$network_config"

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name p-redis \
  --product-properties "$properties_config" \
  --product-resources "$resources_config"
