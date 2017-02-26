#!/bin/bash

chmod +x om-cli/om-linux

IAAS_CONFIGURATION=$(cat <<-EOF
{
  "vcenter_host": "$VCENTER_HOST",
  "vcenter_username": "$VCENTER_USR",
  "vcenter_password": "$VCENTER_PWD",
  "datacenter": "$VCENTER_DATA_CENTER",
  "disk_type": "$VCENTER_DISK_TYPE",
  "ephemeral_datastores_string": "$STORAGE_NAMES",
  "persistent_datastores_string": "$STORAGE_NAMES",
  "bosh_vm_folder": "pcf_vms",
  "bosh_template_folder": "pcf_templates",
  "bosh_disk_path": "pcf_disk",
  "ssl_verification_enabled": false
}
EOF
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

NETWORK_CONFIGURATION=$(cat <<-EOF
{
  "icmp_checks_enabled": true,
  "networks": [
    {
      "name": "$INFRA_NETWORK_NAME",
      "service_network": false,
      "iaas_identifier": "$INFRA_VCENTER_NETWORK",
      "subnets": [
        {
          "cidr": "$INFRA_NW_CIDR",
          "reserved_ip_ranges": "$INFRA_EXCLUDED_RANGE",
          "dns": "$INFRA_NW_DNS",
          "gateway": "$INFRA_NW_GATEWAY",
          "availability_zones": [
            "$INFRA_NW_AZ"
          ]
        }
      ]
    },
    {
      "name": "$DEPLOYMENT_NETWORK_NAME",
      "service_network": false,
      "iaas_identifier": "$DEPLOYMENT_VCENTER_NETWORK",
      "subnets": [
        {
          "cidr": "$DEPLOYMENT_NW_CIDR",
          "reserved_ip_ranges": "$DEPLOYMENT_EXCLUDED_RANGE",
          "dns": "$DEPLOYMENT_NW_DNS",
          "gateway": "$DEPLOYMENT_NW_GATEWAY",
          "availability_zones": [
            "$DEPLOYMENT_NW_AZ"
          ]
        }
      ]
    },
    {
      "name": "$SERVICES_NETWORK_NAME",
      "service_network": true,
      "iaas_identifier": "$SERVICES_VCENTER_NETWORK",
      "subnets": [
        {
          "cidr": "$SERVICES_NW_CIDR",
          "reserved_ip_ranges": "$SERVICES_EXCLUDED_RANGE",
          "dns": "$SERVICES_NW_DNS",
          "gateway": "$SERVICES_NW_GATEWAY",
          "availability_zones": [
            "$SERVICES_NW_AZ"
          ]
        }
      ]
    },
    {
      "name": "$DYNAMIC_SERVICES_NETWORK_NAME",
      "service_network": true,
      "iaas_identifier": "$DYNAMIC_SERVICES_VCENTER_NETWORK",
      "subnets": [
        {
          "cidr": "$DYNAMIC_SERVICES_NW_CIDR",
          "reserved_ip_ranges": "$DYNAMIC_SERVICES_EXCLUDED_RANGE",
          "dns": "$DYNAMIC_SERVICES_NW_DNS",
          "gateway": "$DYNAMIC_SERVICES_NW_GATEWAY",
          "availability_zones": [
            "$DYNAMIC_SERVICES_NW_AZ"
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
  "ntp_servers_string": "$NTP_SERVER_IPS",
  "metrics_ip": null,
  "resurrector_enabled": true,
  "max_threads": null,
  "database_type": "internal",
  "blobstore_type": "local",
  "director_hostname": "$OPS_DIR_HOSTNAME"
}
EOF
)

NETWORK_ASSIGNMENT=$(cat <<-EOF
{
  "singleton_availability_zone": "$AZ_1",
  "network": "$INFRA_NETWORK_NAME"
}
EOF
)

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-bosh \
            -i "$IAAS_CONFIGURATION" \
            -d "$DIRECTOR_CONFIG"

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
            curl -p "/api/v0/staged/director/availability_zones" \
            -x PUT -d "$AZ_CONFIGURATION"

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-bosh -na "$NETWORK_ASSIGNMENT"  \
            -n "$NETWORK_CONFIGURATION"
