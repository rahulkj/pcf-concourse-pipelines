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
  --arg allow_lower_case_table_names_via_config_param "${ALLOW_LOWER_CASE_TABLE_NAMES_VIA_CONFIG_PARAM:-false}" \
  --arg audit_logging_enabled "${AUDIT_LOGGING_ENABLED:-false}" \
  --arg backups_selector "${BACKUPS_SELECTOR}" \
  --arg backups_selector_azure_account "${BACKUPS_SELECTOR_AZURE_ACCOUNT}" \
  --arg backups_selector_azure_blob_store_base_url "${BACKUPS_SELECTOR_AZURE_BLOB_STORE_BASE_URL}" \
  --arg backups_selector_azure_container "${BACKUPS_SELECTOR_AZURE_CONTAINER}" \
  --arg backups_selector_azure_cron_schedule \"${BACKUPS_SELECTOR_AZURE_CRON_SCHEDULE:-"0 */8 * * *"}\" \
  --arg backups_selector_azure_enable_email_alerts "${BACKUPS_SELECTOR_AZURE_ENABLE_EMAIL_ALERTS:-false}" \
  --arg backups_selector_azure_path "${BACKUPS_SELECTOR_AZURE_PATH}" \
  --arg backups_selector_azure_storage_access_key "${BACKUPS_SELECTOR_AZURE_STORAGE_ACCESS_KEY}" \
  --arg backups_selector_gcs_bucket_name "${BACKUPS_SELECTOR_GCS_BUCKET_NAME}" \
  --arg backups_selector_gcs_cron_schedule \"${BACKUPS_SELECTOR_GCS_CRON_SCHEDULE:-"0 */8 * * *"}\" \
  --arg backups_selector_gcs_enable_email_alerts "${BACKUPS_SELECTOR_GCS_ENABLE_EMAIL_ALERTS:-false}" \
  --arg backups_selector_gcs_project_id "${BACKUPS_SELECTOR_GCS_PROJECT_ID}" \
  --arg backups_selector_gcs_service_account_json "${BACKUPS_SELECTOR_GCS_SERVICE_ACCOUNT_JSON}" \
  --arg backups_selector_s3_access_key_id "${BACKUPS_SELECTOR_S3_ACCESS_KEY_ID}" \
  --arg backups_selector_s3_bucket_name "${BACKUPS_SELECTOR_S3_BUCKET_NAME}" \
  --arg backups_selector_s3_cron_schedule \"${BACKUPS_SELECTOR_S3_CRON_SCHEDULE:-"0 */8 * * *"}\" \
  --arg backups_selector_s3_enable_email_alerts "${BACKUPS_SELECTOR_S3_ENABLE_EMAIL_ALERTS:-false}" \
  --arg backups_selector_s3_endpoint_url "${BACKUPS_SELECTOR_S3_ENDPOINT_URL}" \
  --arg backups_selector_s3_path "${BACKUPS_SELECTOR_S3_PATH}" \
  --arg backups_selector_s3_region "${BACKUPS_SELECTOR_S3_REGION}" \
  --arg backups_selector_s3_secret_access_key "${BACKUPS_SELECTOR_S3_SECRET_ACCESS_KEY}" \
  --arg backups_selector_scp_cron_schedule \"${BACKUPS_SELECTOR_SCP_CRON_SCHEDULE:-"0 */8 * * *"}\" \
  --arg backups_selector_scp_destination "${BACKUPS_SELECTOR_SCP_DESTINATION}" \
  --arg backups_selector_scp_enable_email_alerts "${BACKUPS_SELECTOR_SCP_ENABLE_EMAIL_ALERTS:-false}" \
  --arg backups_selector_scp_fingerprint "${BACKUPS_SELECTOR_SCP_FINGERPRINT}" \
  --arg backups_selector_scp_key "${BACKUPS_SELECTOR_SCP_KEY}" \
  --arg backups_selector_scp_port "${BACKUPS_SELECTOR_SCP_PORT}" \
  --arg backups_selector_scp_server "${BACKUPS_SELECTOR_SCP_SERVER}" \
  --arg backups_selector_scp_user "${BACKUPS_SELECTOR_SCP_USER}" \
  --arg enable_lower_case_table_names "${ENABLE_LOWER_CASE_TABLE_NAMES:-false}" \
  --arg enable_read_only_admin "${ENABLE_READ_ONLY_ADMIN:-false}" \
  --arg global_service_instance_limit "${GLOBAL_SERVICE_INSTANCE_LIMIT:-50}" \
  --arg local_infile "${LOCAL_INFILE:-false}" \
  --arg mysql_metrics_frequency "${MYSQL_METRICS_FREQUENCY:-30}" \
  --arg plan1_selector "${PLAN1_SELECTOR:-"Active"}" \
  --arg plan1_selector_active_access_dropdown "${PLAN1_SELECTOR_ACTIVE_ACCESS_DROPDOWN:-"enable"}" \
  --arg plan1_selector_active_az_multi_select "${PLAN1_SELECTOR_ACTIVE_AZ_MULTI_SELECT}" \
  --arg plan1_selector_active_description "${PLAN1_SELECTOR_ACTIVE_DESCRIPTION:-"This plan provides a small dedicated MySQL instance."}" \
  --arg plan1_selector_active_disk_size "${PLAN1_SELECTOR_ACTIVE_DISK_SIZE:-"10240"}" \
  --arg plan1_selector_active_instance_limit "${PLAN1_SELECTOR_ACTIVE_INSTANCE_LIMIT}" \
  --arg plan1_selector_active_multi_node_deployment "${PLAN1_SELECTOR_ACTIVE_MULTI_NODE_DEPLOYMENT:-false}" \
  --arg plan1_selector_active_name "${PLAN1_SELECTOR_ACTIVE_NAME:-"db-small"}" \
  --arg plan1_selector_active_vm_type "${PLAN1_SELECTOR_ACTIVE_VM_TYPE:-"xlarge"}" \
  --arg plan2_selector "${PLAN2_SELECTOR:-"Inactive"}" \
  --arg plan2_selector_active_access_dropdown "${PLAN2_SELECTOR_ACTIVE_ACCESS_DROPDOWN:-"enable"}" \
  --arg plan2_selector_active_az_multi_select "${PLAN2_SELECTOR_ACTIVE_AZ_MULTI_SELECT}" \
  --arg plan2_selector_active_description "${PLAN2_SELECTOR_ACTIVE_DESCRIPTION:-"This plan provides a medium dedicated MySQL instance."}" \
  --arg plan2_selector_active_disk_size "${PLAN2_SELECTOR_ACTIVE_DISK_SIZE:-"20480"}" \
  --arg plan2_selector_active_instance_limit "${PLAN2_SELECTOR_ACTIVE_INSTANCE_LIMIT}" \
  --arg plan2_selector_active_multi_node_deployment "${PLAN2_SELECTOR_ACTIVE_MULTI_NODE_DEPLOYMENT:-false}" \
  --arg plan2_selector_active_name "${PLAN2_SELECTOR_ACTIVE_NAME:-"db-medium"}" \
  --arg plan2_selector_active_vm_type "${PLAN2_SELECTOR_ACTIVE_VM_TYPE:-"xlarge"}" \
  --arg plan3_selector "${PLAN3_SELECTOR:-"Inactive"}" \
  --arg plan3_selector_active_access_dropdown "${PLAN3_SELECTOR_ACTIVE_ACCESS_DROPDOWN:-"enable"}" \
  --arg plan3_selector_active_az_multi_select "${PLAN3_SELECTOR_ACTIVE_AZ_MULTI_SELECT}" \
  --arg plan3_selector_active_description "${PLAN3_SELECTOR_ACTIVE_DESCRIPTION:-"This plan provides a large dedicated MySQL instance."}" \
  --arg plan3_selector_active_disk_size "${PLAN3_SELECTOR_ACTIVE_DISK_SIZE:-"30720"}" \
  --arg plan3_selector_active_instance_limit "${PLAN3_SELECTOR_ACTIVE_INSTANCE_LIMIT}" \
  --arg plan3_selector_active_multi_node_deployment "${PLAN3_SELECTOR_ACTIVE_MULTI_NODE_DEPLOYMENT:-false}" \
  --arg plan3_selector_active_name "${PLAN3_SELECTOR_ACTIVE_NAME:-"db-large"}" \
  --arg plan3_selector_active_vm_type "${PLAN3_SELECTOR_ACTIVE_VM_TYPE:-"xlarge"}" \
  --arg plan4_selector "${PLAN4_SELECTOR:-"Inactive"}" \
  --arg plan4_selector_active_access_dropdown "${PLAN4_SELECTOR_ACTIVE_ACCESS_DROPDOWN:-"enable"}" \
  --arg plan4_selector_active_az_multi_select "${PLAN4_SELECTOR_ACTIVE_AZ_MULTI_SELECT}" \
  --arg plan4_selector_active_description "${PLAN4_SELECTOR_ACTIVE_DESCRIPTION}" \
  --arg plan4_selector_active_disk_size "${PLAN4_SELECTOR_ACTIVE_DISK_SIZE:-"51200"}" \
  --arg plan4_selector_active_instance_limit "${PLAN4_SELECTOR_ACTIVE_INSTANCE_LIMIT}" \
  --arg plan4_selector_active_multi_node_deployment "${PLAN4_SELECTOR_ACTIVE_MULTI_NODE_DEPLOYMENT:-false}" \
  --arg plan4_selector_active_name "${PLAN4_SELECTOR_ACTIVE_NAME}" \
  --arg plan4_selector_active_vm_type "${PLAN4_SELECTOR_ACTIVE_VM_TYPE:-"xlarge"}" \
  --arg plan5_selector "${PLAN5_SELECTOR:-"Inactive"}" \
  --arg plan5_selector_active_access_dropdown "${PLAN5_SELECTOR_ACTIVE_ACCESS_DROPDOWN:-"enable"}" \
  --arg plan5_selector_active_az_multi_select "${PLAN5_SELECTOR_ACTIVE_AZ_MULTI_SELECT}" \
  --arg plan5_selector_active_description "${PLAN5_SELECTOR_ACTIVE_DESCRIPTION}" \
  --arg plan5_selector_active_disk_size "${PLAN5_SELECTOR_ACTIVE_DISK_SIZE:-"76800"}" \
  --arg plan5_selector_active_instance_limit "${PLAN5_SELECTOR_ACTIVE_INSTANCE_LIMIT}" \
  --arg plan5_selector_active_multi_node_deployment "${PLAN5_SELECTOR_ACTIVE_MULTI_NODE_DEPLOYMENT:-false}" \
  --arg plan5_selector_active_name "${PLAN5_SELECTOR_ACTIVE_NAME}" \
  --arg plan5_selector_active_vm_type "${PLAN5_SELECTOR_ACTIVE_VM_TYPE:-"xlarge"}" \
  --arg syslog_migration_selector "${SYSLOG_MIGRATION_SELECTOR:-"disabled"}" \
  --arg syslog_migration_selector_enabled_address "${SYSLOG_MIGRATION_SELECTOR_ENABLED_ADDRESS}" \
  --arg syslog_migration_selector_enabled_ca_cert "${SYSLOG_MIGRATION_SELECTOR_ENABLED_CA_CERT}" \
  --arg syslog_migration_selector_enabled_permitted_peer "${SYSLOG_MIGRATION_SELECTOR_ENABLED_PERMITTED_PEER}" \
  --arg syslog_migration_selector_enabled_port "${SYSLOG_MIGRATION_SELECTOR_ENABLED_PORT}" \
  --arg syslog_migration_selector_enabled_tls_enabled "${SYSLOG_MIGRATION_SELECTOR_ENABLED_TLS_ENABLED:-true}" \
  --arg syslog_migration_selector_enabled_transport_protocol "${SYSLOG_MIGRATION_SELECTOR_ENABLED_TRANSPORT_PROTOCOL:-"tcp"}" \
  --arg userstat "${USERSTAT:-false}" \
  --arg vm_extensions "${VM_EXTENSIONS}" \
'{
  ".properties.global_service_instance_limit": {
    "value": $global_service_instance_limit
  },
  ".properties.mysql_metrics_frequency": {
    "value": $mysql_metrics_frequency
  },
  ".properties.userstat": {
    "value": $userstat
  },
  ".properties.audit_logging_enabled": {
    "value": $audit_logging_enabled
  },
  ".properties.enable_read_only_admin": {
    "value": $enable_read_only_admin
  }
}
+
if $vm_extensions == "public_ip" then
{
  ".properties.vm_extensions": {
    "value": $vm_extensions
  }
}
else .
end
+
{
  ".properties.local_infile": {
    "value": $local_infile
  },
  ".properties.enable_lower_case_table_names": {
    "value": $enable_lower_case_table_names
  },
  ".properties.allow_lower_case_table_names_via_config_param": {
    "value": $allow_lower_case_table_names_via_config_param
  },
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
  ".properties.backups_selector.s3.bucket_name": {
    "value": $backups_selector_s3_bucket_name
  },
  ".properties.backups_selector.s3.path": {
    "value": $backups_selector_s3_path
  },
  ".properties.backups_selector.s3.cron_schedule": {
    "value": $backups_selector_s3_cron_schedule
  },
  ".properties.backups_selector.s3.enable_email_alerts": {
    "value": $backups_selector_s3_enable_email_alerts
  },
  ".properties.backups_selector.s3.region": {
    "value": $backups_selector_s3_region
  }
}
elif $backups_selector == "SCP Backups" then
{
  ".properties.backups_selector.scp.user": {
    "value": $backups_selector_scp_user
  },
  ".properties.backups_selector.scp.server": {
    "value": $backups_selector_scp_server
  },
  ".properties.backups_selector.scp.destination": {
    "value": $backups_selector_scp_destination
  },
  ".properties.backups_selector.scp.fingerprint": {
    "value": $backups_selector_scp_fingerprint
  },
  ".properties.backups_selector.scp.key": {
    "value": $backups_selector_scp_key
  },
  ".properties.backups_selector.scp.port": {
    "value": $backups_selector_scp_port
  },
  ".properties.backups_selector.scp.cron_schedule": {
    "value": $backups_selector_scp_cron_schedule
  },
  ".properties.backups_selector.scp.enable_email_alerts": {
    "value": $backups_selector_scp_enable_email_alerts
  }
}
elif $backups_selector == "GCS" then
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
  ".properties.backups_selector.gcs.enable_email_alerts": {
    "value": $backups_selector_gcs_enable_email_alerts
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
  ".properties.backups_selector.azure.container": {
    "value": $backups_selector_azure_container
  },
  ".properties.backups_selector.azure.blob_store_base_url": {
    "value": $backups_selector_azure_blob_store_base_url
  },
  ".properties.backups_selector.azure.enable_email_alerts": {
    "value": $backups_selector_azure_enable_email_alerts
  }
}
else .
end
+
{
  ".properties.plan1_selector": {
    "value": $plan1_selector
  },
  ".properties.plan1_selector.active.multi_node_deployment": {
    "value": $plan1_selector_active_multi_node_deployment
  },
  ".properties.plan1_selector.active.vm_type": {
    "value": $plan1_selector_active_vm_type
  },
  ".properties.plan1_selector.active.disk_size": {
    "value": $plan1_selector_active_disk_size
  },
  ".properties.plan1_selector.active.az_multi_select": {
    "value": ( $plan1_selector_active_az_multi_select | split(",") )
  },
  ".properties.plan1_selector.active.access_dropdown": {
    "value": $plan1_selector_active_access_dropdown
  },
  ".properties.plan1_selector.active.name": {
    "value": $plan1_selector_active_name
  },
  ".properties.plan1_selector.active.description": {
    "value": $plan1_selector_active_description
  },
  ".properties.plan1_selector.active.instance_limit": {
    "value": $plan1_selector_active_instance_limit
  }
}
+
{
  ".properties.plan2_selector": {
    "value": $plan2_selector
  }
}
+
if $plan2_selector == "active" then
{
  ".properties.plan2_selector.active.multi_node_deployment": {
    "value": $plan2_selector_active_multi_node_deployment
  },
  ".properties.plan2_selector.active.vm_type": {
    "value": $plan2_selector_active_vm_type
  },
  ".properties.plan2_selector.active.disk_size": {
    "value": $plan2_selector_active_disk_size
  },
  ".properties.plan2_selector.active.az_multi_select": {
    "value": ( $plan2_selector_active_az_multi_select | split(",") )
  },
  ".properties.plan2_selector.active.access_dropdown": {
    "value": $plan2_selector_active_access_dropdown
  },
  ".properties.plan2_selector.active.name": {
    "value": $plan2_selector_active_name
  },
  ".properties.plan2_selector.active.description": {
    "value": $plan2_selector_active_description
  },
  ".properties.plan2_selector.active.instance_limit": {
    "value": $plan2_selector_active_instance_limit
  }
}
else .
end
+
{
  ".properties.plan3_selector": {
    "value": $plan3_selector
  }
}
+
if $plan3_selector == "active" then
{
  ".properties.plan3_selector.active.multi_node_deployment": {
    "value": $plan3_selector_active_multi_node_deployment
  },
  ".properties.plan3_selector.active.vm_type": {
    "value": $plan3_selector_active_vm_type
  },
  ".properties.plan3_selector.active.disk_size": {
    "value": $plan3_selector_active_disk_size
  },
  ".properties.plan3_selector.active.az_multi_select": {
    "value": ( $plan3_selector_active_az_multi_select | split(",") )
  },
  ".properties.plan3_selector.active.access_dropdown": {
    "value": $plan3_selector_active_access_dropdown
  },
  ".properties.plan3_selector.active.name": {
    "value": $plan3_selector_active_name
  },
  ".properties.plan3_selector.active.description": {
    "value": $plan3_selector_active_description
  },
  ".properties.plan3_selector.active.instance_limit": {
    "value": $plan3_selector_active_instance_limit
  }
}
else .
end
{
  ".properties.plan4_selector": {
    "value": $plan4_selector
  }
}
+
if $plan4_selector == "active" then
{
  ".properties.plan4_selector.active.multi_node_deployment": {
    "value": $plan4_selector_active_multi_node_deployment
  },
  ".properties.plan4_selector.active.vm_type": {
    "value": $plan4_selector_active_vm_type
  },
  ".properties.plan4_selector.active.disk_size": {
    "value": $plan4_selector_active_disk_size
  },
  ".properties.plan4_selector.active.az_multi_select": {
    "value": ( $plan4_selector_active_az_multi_select | split(",") )
  },
  ".properties.plan4_selector.active.access_dropdown": {
    "value": $plan4_selector_active_access_dropdown
  },
  ".properties.plan4_selector.active.name": {
    "value": $plan4_selector_active_name
  },
  ".properties.plan4_selector.active.description": {
    "value": $plan4_selector_active_description
  },
  ".properties.plan4_selector.active.instance_limit": {
    "value": $plan4_selector_active_instance_limit
  }
}
else .
end
+
{
  ".properties.plan5_selector": {
    "value": $plan5_selector
  }
}
+
if $plan5_selector == "active" then
{
  ".properties.plan5_selector.active.multi_node_deployment": {
    "value": $plan5_selector_active_multi_node_deployment
  },
  ".properties.plan5_selector.active.vm_type": {
    "value": $plan5_selector_active_vm_type
  },
  ".properties.plan5_selector.active.disk_size": {
    "value": $plan5_selector_active_disk_size
  },
  ".properties.plan5_selector.active.az_multi_select": {
    "value": ($plan5_selector_active_az_multi_select | split(",") )
  },
  ".properties.plan5_selector.active.access_dropdown": {
    "value": $plan5_selector_active_access_dropdown
  },
  ".properties.plan5_selector.active.name": {
    "value": $plan5_selector_active_name
  },
  ".properties.plan5_selector.active.description": {
    "value": $plan5_selector_active_description
  },
  ".properties.plan5_selector.active.instance_limit": {
    "value": $plan5_selector_active_instance_limit
  }
}
else .
end
+
{
  ".properties.syslog_migration_selector": {
    "value": $syslog_migration_selector
  }
}
+
if $syslog_migration_selector == "enabled" then
{
  ".properties.syslog_migration_selector.enabled.address": {
    "value": $syslog_migration_selector_enabled_address
  },
  ".properties.syslog_migration_selector.enabled.port": {
    "value": $syslog_migration_selector_enabled_port
  },
  ".properties.syslog_migration_selector.enabled.transport_protocol": {
    "value": $syslog_migration_selector_enabled_transport_protocol
  },
  ".properties.syslog_migration_selector.enabled.tls_enabled": {
    "value": $syslog_migration_selector_enabled_tls_enabled
  },
  ".properties.syslog_migration_selector.enabled.permitted_peer": {
    "value": $syslog_migration_selector_enabled_permitted_peer
  },
  ".properties.syslog_migration_selector.enabled.ca_cert": {
    "value": $syslog_migration_selector_enabled_ca_cert
  }
}
else .
end
'
)

resources_config="{
  \"dedicated-mysql-broker\": {\"instances\": ${DEDICATED_MYSQL_BROKER_INSTANCES:-1}, \"instance_type\": { \"id\": \"${DEDICATED_MYSQL_BROKER_INSTANCE_TYPE:-micro}\"}}
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
  --product-name pivotal-mysql \
  --product-network "$network_config"

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name pivotal-mysql \
  --product-properties "$properties_config" \
  --product-resources "$resources_config"
