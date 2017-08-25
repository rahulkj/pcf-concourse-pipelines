#!/bin/bash -ex

chmod +x om-cli/om-linux

CMD=./om-cli/om-linux

function fn_get_azs {
     local azs_csv=$1
     echo $azs_csv | awk -F "," -v quote='"' -v OFS='", "' '$1=$1 {print quote $0 quote}'
}

IAAS_CONFIGURATION=$(cat <<-EOF
{
  "vcenter_host": "$VCENTER_HOST",
  "vcenter_username": "$VCENTER_USR",
  "vcenter_password": "$VCENTER_PWD",
  "datacenter": "$VCENTER_DATA_CENTER",
  "disk_type": "$VCENTER_DISK_TYPE",
  "ephemeral_datastores_string": "$EPHEMERAL_STORAGE_NAMES",
  "persistent_datastores_string": "$PERSISTENT_STORAGE_NAMES",
  "bosh_vm_folder": "$BOSH_VM_FOLDER",
  "bosh_template_folder": "$BOSH_TEMPLATES_FOLDER",
  "bosh_disk_path": "$BOSH_DISK_PATH"
}
EOF
)

if [[ "$NSX_NETWORKING_ENABLED" == "true" ]]; then
NSX_IAAS_CONFIGURATION=$(cat <<-EOF
{
  "iaas_configuration": {
    "nsx_networking_enabled": $NSX_NETWORKING_ENABLED,
    "nsx_address": "$NSX_ADDRESS",
    "nsx_password": "$NSX_PASSWORD",
    "nsx_username": "$NSX_USERNAME",
    "ssl_verification_enabled": $SSL_VERIFICATION_ENABLED
  }
}
EOF
)
elif [[ "$NSX_NETWORKING_ENABLED" == "false" ]]; then
NSX_IAAS_CONFIGURATION=$(cat <<-EOF
{
  "iaas_configuration": {
    "nsx_networking_enabled": $NSX_NETWORKING_ENABLED
  }
}
EOF
)
fi

if [[ ! -z "$NSX_CA_CERTIFICATE" ]]; then
NSX_SSL_IAAS_CONFIGURATION=$(cat <<-EOF
{
  "iaas_configuration": {
    "nsx_ca_certificate": "$NSX_CA_CERTIFICATE"
  }
}
EOF
)
fi

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
      "service_network": "false",
      "subnets": [
        {
          "iaas_identifier": "$INFRA_VCENTER_NETWORK",
          "cidr": "$INFRA_NW_CIDR",
          "reserved_ip_ranges": "$INFRA_EXCLUDED_RANGE",
          "dns": "$INFRA_NW_DNS",
          "gateway": "$INFRA_NW_GATEWAY",
          "availability_zone_names": [
            $INFRA_AZS
          ]
        }
      ]
    },
    {
      "name": "$DEPLOYMENT_NETWORK_NAME",
      "service_network": "false",
      "subnets": [
        {
          "iaas_identifier": "$DEPLOYMENT_VCENTER_NETWORK",
          "cidr": "$DEPLOYMENT_NW_CIDR",
          "reserved_ip_ranges": "$DEPLOYMENT_EXCLUDED_RANGE",
          "dns": "$DEPLOYMENT_NW_DNS",
          "gateway": "$DEPLOYMENT_NW_GATEWAY",
          "availability_zone_names": [
            $DEPLOYMENT_AZS
          ]
        }
      ]
    },
    {
      "name": "$SERVICES_NETWORK_NAME",
      "service_network": "$SERVICES_NW_IS_SERVICE_NW",
      "subnets": [
        {
          "iaas_identifier": "$SERVICES_VCENTER_NETWORK",
          "cidr": "$SERVICES_NW_CIDR",
          "reserved_ip_ranges": "$SERVICES_EXCLUDED_RANGE",
          "dns": "$SERVICES_NW_DNS",
          "gateway": "$SERVICES_NW_GATEWAY",
          "availability_zone_names": [
            $SERVICES_AZS
          ]
        }
      ]
    },
    {
      "name": "$DYNAMIC_SERVICES_NETWORK_NAME",
      "service_network": "$DYNAMIC_SERVICES_NW_IS_SERVICE_NW",
      "subnets": [
        {
          "iaas_identifier": "$DYNAMIC_SERVICES_VCENTER_NETWORK",
          "cidr": "$DYNAMIC_SERVICES_NW_CIDR",
          "reserved_ip_ranges": "$DYNAMIC_SERVICES_EXCLUDED_RANGE",
          "dns": "$DYNAMIC_SERVICES_NW_DNS",
          "gateway": "$DYNAMIC_SERVICES_NW_GATEWAY",
          "availability_zone_names": [
            $DYNAMIC_SERVICES_AZS
          ]
        }
      ]
    }
  ]
}
EOF
)

DIRECTOR_CONFIG=$(cat <<-EOF
{
  "ntp_servers_string": "$NTP_SERVERS",
  "resurrector_enabled": $ENABLE_VM_RESURRECTOR,
  "metrics_ip": "$METRICS_IP",
  "opentsdb_ip": "$OPENTSDB_IP",
  "post_deploy_enabled": $POST_DEPLOY_ENABLED,
  "bosh_recreate_on_next_deploy": $BOSH_RECREATE_ON_NEXT_DEPLOY,
  "retry_bosh_deploys": $RETRY_BOSH_DEPLOYS,
  "keep_unreachable_vms": $KEEP_UNREACHABLE_VMS,
  "max_threads": $MAX_THREADS,
  "director_worker_count": "$DIRECTOR_WORKER_COUNT",
  "director_hostname": "$OPS_DIR_HOSTNAME"
}
EOF
)

if [[ "$PAGER_DUTY_ENABLED" == "true" ]]; then
PAGER_DUTY_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "hm_pager_duty_options": {
      "enabled": "$PAGER_DUTY_ENABLED",
      "service_key": "$PAGER_DUTY_SERVICE_KEY",
      "http_proxy": "$PAGER_DUTY_HTTP_PROXY"
    }
  }
}
EOF
)
elif [[ "$PAGER_DUTY_ENABLED" == "false" ]]; then
PAGER_DUTY_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "hm_pager_duty_options": {
      "enabled": "$PAGER_DUTY_ENABLED"
    }
  }
}
EOF
)
fi

if [[ "$HM_EMAIL_ENABLED" == "true" ]]; then
SMTP_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "hm_emailer_options": {
      "enabled": "$HM_EMAIL_ENABLED",
      "host": "$SMTP_HOST",
      "port": "$SMTP_PORT",
      "domain": "$SMTP_DOMAIN",
      "from": "$FROM_ADDRESS",
      "recipients": {
        "value": "$RECIPIENTS_ADDRESS"
      },
      "smtp_user": "$SMTP_USER",
      "smtp_password": "$SMTP_PASSWORD",
      "tls": "$SMTP_TLS_ENABLED"
    }
  }
}
EOF
)
elif [[ "$HM_EMAIL_ENABLED" == "false" ]]; then
SMTP_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "hm_emailer_options": {
      "enabled": "$HM_EMAIL_ENABLED"
    }
  }
}
EOF
)
fi

if [[ "$BLOBSTORE_TYPE" == "s3" ]]; then
BLOBSTORE_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "blobstore_type": "$BLOBSTORE_TYPE",
    "s3_blobstore_options": {
      "endpoint": "$S3_ENDPOINT",
      "bucket_name": "$S3_BUCKET_NAME",
      "access_key": "$S3_ACCESS_KEY",
      "secret_key": "$S3_SECRET_KEY",
      "signature_version": "$S3_SIGNATURE_VERSION"
    }
  }
}
EOF
)
elif [[ "$BLOBSTORE_TYPE" == "internal" ]]; then
BLOBSTORE_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "blobstore_type": "$BLOBSTORE_TYPE"
  }
}
EOF
)
fi

if [[ "$DATABASE_TYPE" == "external" ]]; then
DATABASE_LOCATION_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "database_type": "$DATABASE_TYPE",
    "external_database_options": {
      "host": "$EXTERNAL_MYSQL_DB_HOST",
      "port": "$EXTERNAL_MYSQL_DB_PORT",
      "user": "$EXTERNAL_MYSQL_DB_USER",
      "password": "$EXTERNAL_MYSQL_DB_PASSWORD",
      "database": "$EXTERNAL_MYSQL_DB_DATABASE"
    }
  }
}
EOF
)
elif [[ "$DATABASE_TYPE" == "internal" ]]; then
DATABASE_LOCATION_CONFIG=$(cat <<-EOF
{
  "director_configuration": {
    "database_type": "$DATABASE_TYPE"
  }
}
EOF
)
fi

SECURITY_CONFIG=$(cat <<-EOF
{
  "security_configuration": {
    "generate_vm_passwords": $GENERATE_VM_PASSWORDS,
    "trusted_certificates": "$TRUSTED_CERTIFICATES"
  }
}
EOF
)

NETWORK_ASSIGNMENT=$(cat <<-EOF
{
  "network_and_az": {
     "network": {
       "name": "$INFRA_NETWORK_NAME"
     },
     "singleton_availability_zone": {
       "name": "$AZ_1"
     }
  }
}
EOF
)

if [[ "$SYSLOG_ENABLED" == "true" ]]; then
SYSLOG_CONFIG=$(cat <<-EOF
{
  "syslog_configuration": {
    "enabled": $SYSLOG_ENABLED,
    "address": "$SYSLOG_ADDRESS",
    "port": "$SYSLOG_PORT",
    "transport_protocol": "$SYSLOG_TRANSPORT_PROTOCOL"
  }
}
EOF
)
elif [[ "$SYSLOG_ENABLED" == "false" ]]; then
SYSLOG_CONFIG=$(cat <<-EOF
{
  "syslog_configuration": {
    "enabled": $SYSLOG_ENABLED
  }
}
EOF
)
fi

if [[ "$SYSLOG_ENABLED" == "true" && "$SYSLOG_TLS_ENABLED" == "true" ]]; then
SYSLOG_TLS_CONFIG=$(cat <<-EOF
{
  "syslog_configuration": {
    "tls_enabled": $SYSLOG_TLS_ENABLED,
    "permitted_peer": "$SYSLOG_PERMITTED_PEER",
    "ssl_ca_certificate": "$SYSLOG_SSL_CA_CERTIFICATE"
  }
}
EOF
)
elif [[ "$SYSLOG_ENABLED" == "true" && "$SYSLOG_TLS_ENABLED" == "false" ]]; then
SYSLOG_TLS_CONFIG=$(cat <<-EOF
{
  "syslog_configuration": {
    "tls_enabled": $SYSLOG_TLS_ENABLED
  }
}
EOF
)
fi

echo "Configuring IaaS and Director..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-bosh \
            -i "$IAAS_CONFIGURATION" \
            -d "$DIRECTOR_CONFIG"

echo "Configuring NSX..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$NSX_IAAS_CONFIGURATION"

$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$NSX_SSL_IAAS_CONFIGURATION"

echo "Configuring Pager Duty..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$PAGER_DUTY_CONFIG"

echo "Configuring SMTP..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$SMTP_CONFIG"

echo "Configuring Blobstore..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$BLOBSTORE_CONFIG"

echo "Configuring Database..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$DATABASE_LOCATION_CONFIG"

echo "Configuring availability zones..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/availability_zones" \
            -x PUT -d "$AZ_CONFIGURATION"

echo "Configuring networks..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/networks" \
            -x PUT -d "$NETWORK_CONFIGURATION"

echo "Configuring network assignment..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/network_and_az" \
            -x PUT -d "$NETWORK_ASSIGNMENT"

echo "Configuring security..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$SECURITY_CONFIG"

echo "Configuring syslog..."
$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$SYSLOG_CONFIG"

$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/properties" \
            -x PUT -d "$SYSLOG_TLS_CONFIG"
