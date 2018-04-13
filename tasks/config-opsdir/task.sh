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

IAAS_CONFIGURATION=$(
  echo "{}" |
    $JQ_CMD -n \
    --arg vcenter_host "${VCENTER_HOST}" \
    --arg vcenter_username "${VCENTER_USR}" \
    --arg vcenter_password "${VCENTER_PWD}" \
    --arg datacenter "${VCENTER_DATA_CENTER}" \
    --arg disk_type "${VCENTER_DISK_TYPE}" \
    --arg ephemeral_datastores_string "${EPHEMERAL_STORAGE_NAMES}" \
    --arg persistent_datastores_string "${PERSISTENT_STORAGE_NAMES}" \
    --arg bosh_vm_folder "${BOSH_VM_FOLDER}" \
    --arg bosh_template_folder "${BOSH_TEMPLATE_FOLDER}" \
    --arg bosh_disk_path "${BOSH_DISK_PATH}" \
    --argjson ssl_verification_enabled ${SSL_VERIFICATION_ENABLED:-false} \
    --argjson nsx_networking_enabled ${NSX_NETWORKING_ENABLED:-false} \
    --arg nsx_mode "${NSX_MODE}" \
    --arg nsx_address "${NSX_ADDRESS}" \
    --arg nsx_username "${NSX_USERNAME}" \
    --arg nsx_password "${NSX_PASSWORD}" \
    --arg nsx_ca_certificate "${NSX_CA_CERTIFICATE}" \
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

AZ_CONFIGURATION=$(
  $JQ_CMD -n \
    --arg az_1 "$AZ_1" \
    --arg az_1_custer_name "$AZ_1_CLUSTER_NAME" \
    --arg az_1_rp_name "$AZ_1_RP_NAME" \
    --arg az_2 "$AZ_2" \
    --arg az_2_custer_name "$AZ_2_CLUSTER_NAME" \
    --arg az_2_rp_name "$AZ_2_RP_NAME" \
    --arg az_3 "$AZ_3" \
    --arg az_3_custer_name "$AZ_3_CLUSTER_NAME" \
    --arg az_3_rp_name "$AZ_3_RP_NAME" \
    '
    {
      "availability_zones": [
        {
          "name": $az_1,
          "clusters": [
            {
              "cluster": $az_1_custer_name,
              "resource_pool": $az_1_rp_name
            }
          ]
        },
        {
          "name": $az_2,
          "clusters": [
            {
              "cluster": $az_2_custer_name,
              "resource_pool": $az_2_rp_name
            }
          ]
        },
        {
          "name": $az_3,
          "clusters": [
            {
              "cluster": $az_3_custer_name,
              "resource_pool": $az_3_rp_name
            }
          ]
        }
      ]
    }
    '
)

NETWORK_CONFIGURATION=$(
  $JQ_CMD -n \
  --argjson icmp_checks_enabled "$ICMP_CHECKS_ENABLED" \
  --arg infra_network_name "$INFRA_NETWORK_NAME" \
  --arg infra_vcenter_network "$INFRA_VCENTER_NETWORK" \
  --arg infra_nw_cidr "$INFRA_NW_CIDR" \
  --arg infra_excluded_range "$INFRA_EXCLUDED_RANGE" \
  --arg infra_nw_dns "$INFRA_NW_DNS" \
  --arg infra_nw_gateway "$INFRA_NW_GATEWAY" \
  --arg infra_nw_azs "$INFRA_NW_AZS" \
  --arg deployment_network_name "$DEPLOYMENT_NETWORK_NAME" \
  --arg deployment_vcenter_network "$DEPLOYMENT_VCENTER_NETWORK" \
  --arg deployment_nw_cidr "$DEPLOYMENT_NW_CIDR" \
  --arg deployment_excluded_range "$DEPLOYMENT_EXCLUDED_RANGE" \
  --arg deployment_nw_dns "$DEPLOYMENT_NW_DNS" \
  --arg deployment_nw_gateway "$DEPLOYMENT_NW_GATEWAY" \
  --arg deployment_nw_azs "$DEPLOYMENT_NW_AZS" \
  --arg services_network_name "$SERVICES_NETWORK_NAME" \
  --arg services_vcenter_network "$SERVICES_VCENTER_NETWORK" \
  --arg services_nw_cidr "$SERVICES_NW_CIDR" \
  --arg services_excluded_range "$SERVICES_EXCLUDED_RANGE" \
  --arg services_nw_dns "$SERVICES_NW_DNS" \
  --arg services_nw_gateway "$SERVICES_NW_GATEWAY" \
  --arg services_nw_azs "$SERVICES_NW_AZS" \
  --arg dynamic_services_network_name "$DYNAMIC_SERVICES_NETWORK_NAME" \
  --arg dynamic_services_vcenter_network "$DYNAMIC_SERVICES_VCENTER_NETWORK" \
  --arg dynamic_services_nw_cidr "$DYNAMIC_SERVICES_NW_CIDR" \
  --arg dynamic_services_excluded_range "$DYNAMIC_SERVICES_EXCLUDED_RANGE" \
  --arg dynamic_services_nw_dns "$DYNAMIC_SERVICES_NW_DNS" \
  --arg dynamic_services_nw_gateway "$DYNAMIC_SERVICES_NW_GATEWAY" \
  --arg dynamic_services_nw_azs "$DYNAMIC_SERVICES_NW_AZS" \
  '
  {
    "icmp_checks_enabled": $icmp_checks_enabled,
    "networks": [
      {
        "name": $infra_network_name,
        "subnets": [
          {
            "iaas_identifier": $infra_vcenter_network,
            "cidr": $infra_nw_cidr,
            "reserved_ip_ranges": $infra_excluded_range,
            "dns": $infra_nw_dns,
            "gateway": $infra_nw_gateway,
            "availability_zone_names": ($infra_nw_azs | split(","))
          }
        ]
      },
      {
        "name": $deployment_network_name,
        "subnets": [
          {
            "iaas_identifier": $deployment_vcenter_network,
            "cidr": $deployment_nw_cidr,
            "reserved_ip_ranges": $deployment_excluded_range,
            "dns": $deployment_nw_dns,
            "gateway": $deployment_nw_gateway,
            "availability_zone_names": ($deployment_nw_azs | split(","))
          }
        ]
      },
      {
        "name": $services_network_name,
        "subnets": [
          {
            "iaas_identifier": $services_vcenter_network,
            "cidr": $services_nw_cidr,
            "reserved_ip_ranges": $services_excluded_range,
            "dns": $services_nw_dns,
            "gateway": $services_nw_gateway,
            "availability_zone_names": ($services_nw_azs | split(","))
          }
        ]
      },
      {
        "name": $dynamic_services_network_name,
        "subnets": [
          {
            "iaas_identifier": $dynamic_services_vcenter_network,
            "cidr": $dynamic_services_nw_cidr,
            "reserved_ip_ranges": $dynamic_services_excluded_range,
            "dns": $dynamic_services_nw_dns,
            "gateway": $dynamic_services_nw_gateway,
            "availability_zone_names": ($dynamic_services_nw_azs | split(","))
          }
        ]
      }
    ]
  }
  '
)

DIRECTOR_CONFIG=$(
  echo "{}" |
  $JQ_CMD -n \
  --arg ntp_servers ${NTP_SERVERS:-''} \
  --argjson enable_vm_resurrector ${ENABLE_VM_RESURRECTOR:-true} \
  --arg metrics_ip ${METRICS_IP:-''} \
  --arg opentsdb_ip ${OPENTSDB_IP:-''} \
  --argjson post_deploy_enabled ${POST_DEPLOY_ENABLED:-true} \
  --argjson bosh_recreate_on_next_deploy ${BOSH_RECREATE_ON_NEXT_DEPLOY:-false} \
  --argjson retry_bosh_deploys ${RETRY_BOSH_DEPLOYS:-false} \
  --argjson keep_unreachable_vms ${KEEP_UNREACHABLE_VMS:-false} \
  --argjson max_threads ${MAX_THREADS:-5} \
  --argjson director_worker_count ${DIRECTOR_WORKER_COUNT:-5} \
  --arg ops_dir_hostname ${OPS_DIR_HOSTNAME:-''} \
  --argjson pager_duty_enabled ${PAGER_DUTY_ENABLED:-false} \
  --arg pager_duty_service_key ${PAGER_DUTY_SERVICE_KEY:-''} \
  --arg pager_duty_http_proxy ${PAGER_DUTY_HTTP_PROXY:-''} \
  --argjson hm_email_enabled ${HM_EMAIL_ENABLED:-false} \
  --arg smtp_host ${SMTP_HOST:-''} \
  --argjson smtp_port ${SMTP_PORT:-5514} \
  --arg smtp_domain ${SMTP_DOMAIN:-''} \
  --arg from_address ${FROM_ADDRESS:-''} \
  --arg recipients_address ${RECIPIENTS_ADDRESS:-''} \
  --arg smtp_user ${SMTP_USER:-''} \
  --arg smtp_password ${SMTP_PASSWORD:-''} \
  --argjson smtp_tls_enabled ${SMTP_TLS_ENABLED:-false} \
  --arg blobstore_type ${BLOBSTORE_TYPE:-''} \
  --arg s3_endpoint ${S3_ENDPOINT:-''} \
  --arg s3_bucket_name ${S3_BUCKET_NAME:-''} \
  --arg s3_access_key ${S3_ACCESS_KEY:-''} \
  --arg s3_secret_key ${S3_SECRET_KEY:-''} \
  --arg s3_signature_version ${S3_SIGNATURE_VERSION:-''} \
  --arg database_type ${DATABASE_TYPE:-"internal"} \
  --arg external_mysql_db_host ${EXTERNAL_MYSQL_DB_HOST:-''} \
  --arg external_mysql_db_port ${EXTERNAL_MYSQL_DB_PORT:-''} \
  --arg external_mysql_db_user ${EXTERNAL_MYSQL_DB_USER:-''} \
  --arg external_mysql_db_password ${EXTERNAL_MYSQL_DB_PASSWORD:-''} \
  --arg external_mysql_db_database ${EXTERNAL_MYSQL_DB_DATABASE:-''} \
  --argjson syslog_enabled ${SYSLOG_ENABLED:-false} \
  --arg syslog_address ${SYSLOG_ADDRESS:-''} \
  --argjson syslog_port ${SYSLOG_PORT:-5514} \
  --arg syslog_transport_protocol ${SYSLOG_TRANSPORT_PROTOCOL:-'tcp'} \
  --argjson syslog_tls_enabled ${SYSLOG_TLS_ENABLED:-false} \
  --arg syslog_permitted_peer ${SYSLOG_PERMITTED_PEER:-''} \
  --arg syslog_ssl_ca_certificate ${SYSLOG_SSL_CA_CERTIFICATE:-''} \
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

SECURITY_CONFIG=$(
  $JQ_CMD -n \
  --argjson generate_vm_passwords ${GENERATE_VM_PASSWORDS:-true} \
  --arg trusted_certificates "${TRUSTED_CERTIFICATES}" \
  '
  .+
  {
    "security_configuration": {
      "generate_vm_passwords": $generate_vm_passwords,
      "trusted_certificates": $trusted_certificates
    }
  }
  '
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
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-director \
  -i "$IAAS_CONFIGURATION" \
  -d "$DIRECTOR_CONFIG"

echo "Configuring availability zones..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  curl -p "/api/v0/staged/director/availability_zones" \
  -x PUT -d "$AZ_CONFIGURATION"


echo "Configuring network..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  curl -p "/api/v0/staged/director/networks" \
  -x PUT -d "$NETWORK_CONFIGURATION"

echo "Configuring network assignment, security..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  configure-director \
  --network-assignment "$NETWORK_ASSIGNMENT" \
  --security-configuration "$SECURITY_CONFIG" \
  --resource-configuration "$RESOURCE_CONFIG"
