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
  --arg singleton_az ${SINGLETON_JOBS_AZ:-''} \
  --arg backups ${BACKUPS:-"s3"} \
  --arg backups_azure_base_url ${BACKUPS_AZURE_BASE_URL:-''} \
  --arg backups_azure_container ${BACKUPS_AZURE_CONTAINER:-''} \
  --arg backups_azure_container_path ${BACKUPS_AZURE_CONTAINER_PATH:-''} \
  --arg backups_azure_storage_access_key ${BACKUPS_AZURE_STORAGE_ACCESS_KEY:-''} \
  --arg backups_azure_storage_account ${BACKUPS_AZURE_STORAGE_ACCOUNT:-''} \
  --arg backups_s3_access_key_id ${BACKUPS_S3_ACCESS_KEY_ID:-''} \
  --arg backups_s3_bucket_name ${BACKUPS_S3_BUCKET_NAME:-''} \
  --arg backups_s3_bucket_path ${BACKUPS_S3_BUCKET_PATH:-''} \
  --arg backups_s3_endpoint_url ${BACKUPS_S3_ENDPOINT_URL:-''} \
  --arg backups_s3_region ${BACKUPS_S3_REGION:-''} \
  --arg backups_s3_secret_access_key ${BACKUPS_S3_SECRET_ACCESS_KEY:-''} \
  --arg backups_gcs_bucket_name ${BACKUPS_GCS_BUCKET_NAME:-''} \
  --arg backups_gcs_project_id ${BACKUPS_GCS_PROJECT_ID:-''} \
  --argjson backups_gcs_service_account_json ${BACKUPS_GCS_SERVICE_ACCOUNT_JSON:-''} \
  --arg backups_scp_destination ${BACKUPS_SCP_DESTINATION:-''} \
  --arg backups_scp_port ${BACKUPS_SCP_PORT:-22} \
  --arg backups_scp_scp_key ${BACKUPS_SCP_SCP_KEY:-''} \
  --arg backups_scp_server ${BACKUPS_SCP_SERVER:-''} \
  --arg backups_scp_user ${BACKUPS_SCP_USER:-''} \
  --arg syslog ${SYSLOG:-"disabled"} \
  --arg syslog_enabled_address ${SYSLOG_ENABLED_ADDRESS:-''} \
  --arg syslog_enabled_port ${SYSLOG_ENABLED_PORT:-6514} \
  --arg syslog_enabled_protocol ${SYSLOG_ENABLED_PROTOCOL:-"tcp"} \
'{
  ".properties.plan1_selector.active.az_multi_select": {
    "value": [ "${singleton_az}"],
  },
  ".properties.plan2_selector.active.az_multi_select": {
    "value": [ "${singleton_az}"],
  },
  ".properties.plan3_selector.active.az_multi_select": {
    "value": [ "${singleton_az}"],
  }
}
+
if $backups == "s3" then
{
  ".properties.backups_selector": {
      "value": "S3 Backups"
  },
  ".properties.backups_selector.s3.endpoint_url": {
    "value": $backups_s3_endpoint_url
  },
  ".properties.backups_selector.s3.bucket_name": {
    "value": $backups_s3_bucket_name
  },
  ".properties.backups_selector.s3.bucket_path": {
    "value": $backups_s3_bucket_path
  },
  ".properties.backups_selector.s3.access_key_id": {
    "value": $backups_s3_access_key_id
  },
  ".properties.backups_selector.s3.secret_access_key": {
    "value": {
      "secret": $backups_s3_secret_access_key
    }
  },
  ".properties.backups_selector.enable.region": {
    "value": $backups_s3_region
  }
}
elif $backups == "azure" then
{
  ".properties.backups_selector": {
      "value": "Azure Backups"
  },
  ".properties.backups_selector.azure.storage_account": {
    "value": $backups_azure_storage_account
  },
  ".properties.backups_selector.azure.storage_access_key": {
    "value": {
      "secret": $backups_azure_storage_access_key
    }
  },
  ".properties.backups_selector.azure.container": {
    "value": $backups_azure_container
  },
  ".properties.backups_selector.azure.container_path": {
    "value": $backups_azure_container_path
  },
  ".properties.backups_selector.azure.base_url": {
    "value": $backups_azure_base_url
  }
}
elif $backups == "gcs" then
{
  ".properties.backups_selector": {
      "value": "GCS"
  },
  ".properties.backups_selector.gcs.service_account_json": {
    "value": {
      "secret": $backups_gcs_service_account_json
    }
  },
  ".properties.backups_selector.gcs.project_id": {
    "value": $backups_gcs_project_id
  },
  ".properties.backups_selector.gcs.bucket_name": {
    "value": $backups_gcs_bucket_name
  }
}
elif $backups == "scp" then
{
  ".properties.backups_selector": {
      "value": "SCP Backups"
  },
  ".properties.backups_selector.scp.user": {
    "value": $backups_scp_user
  },
  ".properties.backups_selector.scp.server": {
    "value": $backups_scp_server
  },
  ".properties.backups_selector.scp.destination": {
    "value": $backups_scp_destination
  },
  ".properties.backups_selector.scp.scp_key": {
    "value": $backups_scp_scp_key
  },
  ".properties.backups_selector.scp.port": {
    "value": $backups_scp_port
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
'
)

resources_config="{
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
  --product-name p-mysql \
  --product-properties "$properties_config" \
  --product-network "$network_config" \
  --product-resources "$resources_config"
