#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

function fn_get_azs {
     local azs_csv=$1
     echo $azs_csv | awk -F "," -v quote='"' -v OFS='", "' '$1=$1 {print quote $0 quote}'
}

IAAS_CONFIGURATION=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg vcenter_host "$VCENTER_HOST" \
    --arg vcenter_username "$VCENTER_USR" \
    --arg vcenter_password "$VCENTER_PWD" \
    --arg datacenter "$VCENTER_DATA_CENTER" \
    --arg disk_type "$VCENTER_DISK_TYPE" \
    --arg ephemeral_datastores_string "$EPHEMERAL_STORAGE_NAMES" \
    --arg persistent_datastores_string "$PERSISTENT_STORAGE_NAMES" \
    --arg bosh_vm_folder "$BOSH_VM_FOLDER" \
    --arg bosh_template_folder "$BOSH_TEMPLATE_FOLDER" \
    --arg bosh_disk_path "$BOSH_DISK_PATH" \
    --argjson ssl_verification_enabled $SSL_VERIFICATION_ENABLED \
    --argjson nsx_networking_enabled $NSX_NETWORKING_ENABLED \
    --arg nsx_mode "$NSX_MODE" \
    --arg nsx_address "$NSX_ADDRESS" \
    --arg nsx_username "$NSX_USERNAME" \
    --arg nsx_password "$NSX_PASSWORD" \
    --arg nsx_ca_certificate "$NSX_CA_CERTIFICATE" \
    '
    . +
    {
      "vcenter_host": $vcenter_host,
      "vcenter_username": $vcenter_username,
      "vcenter_password": $vcenter_password,
      "datacenter": $datacenter,
      "disk_type": $disk_type,
      "ephemeral_datastores_string": $ephemeral_datastores_string,
      "persistent_datastores_string": $persistent_datastores_string,
      "bosh_vm_folder": $bosh_vm_folder,
      "bosh_template_folder": $bosh_template_folder,
      "bosh_disk_path": $bosh_disk_path,
      "nsx_networking_enabled": $nsx_networking_enabled,
      "ssl_verification_enabled": $ssl_verification_enabled
    }
    +
    if $nsx_networking_enabled == "true" then
    {
      "nsx_mode": $nsx_mode,
      "nsx_address": $nsx_address,
      "nsx_username": $nsx_username,
      "nsx_password": $nsx_password
    }
    else .
    end
    +
    if ($nsx_networking_enabled == "true" and $nsx_ca_certificate != "") then
    {
      "nsx_ca_certificate": $nsx_ca_certificate
    }
    else .
    end
    '
)

AZ_CONFIGURATION=$(cat <<-EOF
{
  "availability_zones": [
    {
      "name": "$AZ_1",
      "cluster": "$AZ_1_CUSTER_NAME",
      "resource_pool": "$AZ_1_RP_NAME"
    },
    {
      "name": "$AZ_2",
      "cluster": "$AZ_2_CUSTER_NAME",
      "resource_pool": "$AZ_2_RP_NAME"
    },
    {
      "name": "$AZ_3",
      "cluster": "$AZ_3_CUSTER_NAME",
      "resource_pool": "$AZ_3_RP_NAME"
    }
  ]
}
EOF
)

INFRA_AZS=$(fn_get_azs $INFRA_NW_AZS)
DEPLOYMENT_AZS=$(fn_get_azs $DEPLOYMENT_NW_AZS)
SERVICES_AZS=$(fn_get_azs $SERVICES_NW_AZS)
DYNAMIC_SERVICES_AZS=$(fn_get_azs $DYNAMIC_SERVICES_NW_AZS)

NETWORK_CONFIGURATION=$(cat <<-EOF
{
  "icmp_checks_enabled": $ICMP_CHECKS_ENABLED,
  "networks": [
    {
      "name": "$INFRA_NETWORK_NAME",
      "subnets": [
        {
          "iaas_identifier": "$INFRA_VCENTER_NETWORK",
          "cidr": "$INFRA_NW_CIDR",
          "reserved_ip_ranges": "$INFRA_EXCLUDED_RANGE",
          "dns": "$INFRA_NW_DNS",
          "gateway": "$INFRA_NW_GATEWAY",
          "availability_zones": [
            $INFRA_AZS
          ]
        }
      ]
    },
    {
      "name": "$DEPLOYMENT_NETWORK_NAME",
      "subnets": [
        {
          "iaas_identifier": "$DEPLOYMENT_VCENTER_NETWORK",
          "cidr": "$DEPLOYMENT_NW_CIDR",
          "reserved_ip_ranges": "$DEPLOYMENT_EXCLUDED_RANGE",
          "dns": "$DEPLOYMENT_NW_DNS",
          "gateway": "$DEPLOYMENT_NW_GATEWAY",
          "availability_zones": [
            $DEPLOYMENT_AZS
          ]
        }
      ]
    },
    {
      "name": "$SERVICES_NETWORK_NAME",
      "subnets": [
        {
          "iaas_identifier": "$SERVICES_VCENTER_NETWORK",
          "cidr": "$SERVICES_NW_CIDR",
          "reserved_ip_ranges": "$SERVICES_EXCLUDED_RANGE",
          "dns": "$SERVICES_NW_DNS",
          "gateway": "$SERVICES_NW_GATEWAY",
          "availability_zones": [
            $SERVICES_AZS
          ]
        }
      ]
    },
    {
      "name": "$DYNAMIC_SERVICES_NETWORK_NAME",
      "subnets": [
        {
          "iaas_identifier": "$DYNAMIC_SERVICES_VCENTER_NETWORK",
          "cidr": "$DYNAMIC_SERVICES_NW_CIDR",
          "reserved_ip_ranges": "$DYNAMIC_SERVICES_EXCLUDED_RANGE",
          "dns": "$DYNAMIC_SERVICES_NW_DNS",
          "gateway": "$DYNAMIC_SERVICES_NW_GATEWAY",
          "availability_zones": [
            $DYNAMIC_SERVICES_AZS
          ]
        }
      ]
    }
  ]
}
EOF
)

DIRECTOR_CONFIG=$(
  echo "{}" |
  $JQ_CMD -n \
  --arg ntp_servers "$NTP_SERVERS" \
  --argjson enable_vm_resurrector $ENABLE_VM_RESURRECTOR \
  --arg metrics_ip "$METRICS_IP" \
  --arg opentsdb_ip "$OPENTSDB_IP" \
  --argjson post_deploy_enabled $POST_DEPLOY_ENABLED \
  --argjson bosh_recreate_on_next_deploy $BOSH_RECREATE_ON_NEXT_DEPLOY \
  --argjson retry_bosh_deploys $RETRY_BOSH_DEPLOYS \
  --argjson keep_unreachable_vms $KEEP_UNREACHABLE_VMS \
  --argjson max_threads "$MAX_THREADS" \
  --argjson director_worker_count "$DIRECTOR_WORKER_COUNT" \
  --arg ops_dir_hostname "$OPS_DIR_HOSTNAME" \
  --argjson pager_duty_enabled $PAGER_DUTY_ENABLED \
  --arg pager_duty_service_key "$PAGER_DUTY_SERVICE_KEY" \
  --arg pager_duty_http_proxy "$PAGER_DUTY_HTTP_PROXY" \
  --argjson hm_email_enabled $HM_EMAIL_ENABLED \
  --arg smtp_host "$SMTP_HOST" \
  --argjson smtp_port "$SMTP_PORT" \
  --arg smtp_domain "$SMTP_DOMAIN" \
  --arg from_address "$FROM_ADDRESS" \
  --arg recipients_address "$RECIPIENTS_ADDRESS" \
  --arg smtp_user "$SMTP_USER" \
  --arg smtp_password "$SMTP_PASSWORD" \
  --argjson smtp_tls_enabled $SMTP_TLS_ENABLED \
  --arg blobstore_type "$BLOBSTORE_TYPE" \
  --arg s3_endpoint "$S3_ENDPOINT" \
  --arg s3_bucket_name "$S3_BUCKET_NAME" \
  --arg s3_access_key "$S3_ACCESS_KEY" \
  --arg s3_secret_key "$S3_SECRET_KEY" \
  --arg s3_signature_version "$S3_SIGNATURE_VERSION" \
  --arg database_type "$DATABASE_TYPE" \
  --arg external_mysql_db_host "$EXTERNAL_MYSQL_DB_HOST" \
  --arg external_mysql_db_port "$EXTERNAL_MYSQL_DB_PORT" \
  --arg external_mysql_db_user "$EXTERNAL_MYSQL_DB_USER" \
  --arg external_mysql_db_password "$EXTERNAL_MYSQL_DB_PASSWORD" \
  --arg external_mysql_db_database "$EXTERNAL_MYSQL_DB_DATABASE" \
  --argjson syslog_enabled $SYSLOG_ENABLED \
  --arg syslog_address "$SYSLOG_ADDRESS" \
  --argjson syslog_port "$SYSLOG_PORT" \
  --arg syslog_transport_protocol "$SYSLOG_TRANSPORT_PROTOCOL" \
  --argjson syslog_tls_enabled $SYSLOG_TLS_ENABLED \
  --arg syslog_permitted_peer "$SYSLOG_PERMITTED_PEER" \
  --arg syslog_ssl_ca_certificate "$SYSLOG_SSL_CA_CERTIFICATE" \
  '
  . +
  {
    "ntp_servers_string": $ntp_servers,
    "resurrector_enabled": $enable_vm_resurrector,
    "metrics_ip": $metrics_ip,
    "opentsdb_ip": $opentsdb_ip,
    "post_deploy_enabled": $post_deploy_enabled,
    "bosh_recreate_on_next_deploy": $bosh_recreate_on_next_deploy,
    "retry_bosh_deploys": $retry_bosh_deploys,
    "keep_unreachable_vms": $keep_unreachable_vms,
    "max_threads": $max_threads,
    "director_worker_count": $director_worker_count,
    "director_hostname": $ops_dir_hostname,
    "hm_emailer_options": {
      "enabled": $hm_email_enabled
    },
    "hm_pager_duty_options": {
      "enabled": $pager_duty_enabled
    },
    "blobstore_type": $blobstore_type,
    "database_type": $database_type,
    "syslog_configuration": {
      "enabled": $syslog_enabled
    }
  }
  +
  if $pager_duty_enabled == true then
  {
    "hm_pager_duty_options": {
      "service_key": $pager_duty_service_key,
      "http_proxy": $pager_duty_http_proxy
    }
  }
  else .
  end
  +
  if $hm_email_enabled == true then
  {
    "hm_emailer_options": {
      "host": $smtp_host,
      "port": $smtp_port,
      "domain": $smtp_domain,
      "from": $from_address,
      "recipients": $recipients_address,
      "smtp_user": $smtp_user,
      "smtp_password": $smtp_password,
      "tls": $smtp_tls_enabled
    }
  }
  else .
  end
  +
  if $blobstore_type == "s3" then
  {
    "s3_blobstore_options": {
      "endpoint": $s3_endpoint,
      "bucket_name": $s3_bucket_name,
      "access_key": $s3_access_key,
      "secret_key": $s3_secret_key,
      "signature_version": $s3_signature_version
    }
  }
  else .
  end
  +
  if $database_type == "external" then
  {
    "external_database_options": {
      "host": $external_mysql_db_host,
      "port": $external_mysql_db_port,
      "user": $external_mysql_db_user,
      "password": $external_mysql_db_password,
      "database": $external_mysql_db_database
    }
  }
  else .
  end
  +
  if $syslog_enabled == true and $syslog_tls_enabled == true then
  {
    "syslog_configuration": {
      "address": $syslog_address,
      "port": $syslog_port,
      "transport_protocol": $syslog_transport_protocol,
      "tls_enabled": $syslog_tls_enabled,
      "permitted_peer": $syslog_permitted_peer,
      "ssl_ca_certificate": $syslog_ssl_ca_certificate
    }
  }
  else
  {
    "syslog_configuration": {
      "address": $syslog_address,
      "port": $syslog_port,
      "transport_protocol": $syslog_transport_protocol,
      "tls_enabled": $syslog_tls_enabled
    }
  }
  end
  '
)

NETWORK_ASSIGNMENT=$(cat <<-EOF
{
   "singleton_availability_zone": "$AZ_1",
   "network": "$INFRA_NETWORK_NAME"
}
EOF
)

SECURITY_CONFIG=$(cat <<-EOF
{
  "security_configuration": {
    "generate_vm_passwords": $GENERATE_VM_PASSWORDS,
    "trusted_certificates": "$TRUSTED_CERTIFICATES"
  }
}
EOF
)

RESOURCE_CONFIG=$(cat <<-EOF
{
  "director": {
    "instance_type": {"id": "$DIRECTOR_INSTANCE_TYPE"},
    "instances" : $DIRECTOR_INSTANCES,
    "persistent_disk": { "size_mb": "$DIRECTOR_PERSISTENT_DISK_SIZE_MB" }
  },
  "compilation": {
    "instance_type": {"id": "$COMPILATION_INSTANCE_TYPE"},
    "instances" : $COMPILATION_INSTANCES
  }
}
EOF
)

echo "Configuring IaaS and Director..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-bosh \
  -i "$IAAS_CONFIGURATION" \
  -d "$DIRECTOR_CONFIG"

echo "Configuring availability zones..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  curl -p "/api/v0/staged/director/availability_zones" \
  -x PUT -d "$AZ_CONFIGURATION"

echo "Configuring network, network assignment, security..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  configure-bosh \
  --networks-configuration "$NETWORK_CONFIGURATION" \
  --network-assignment "$NETWORK_ASSIGNMENT" \
  --security-configuration "$SECURITY_CONFIG" \
  --resource-configuration "$RESOURCE_CONFIG"
