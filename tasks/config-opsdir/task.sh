#!/bin/bash

uaac target https://$OPS_MGR_HOST/uaa --skip-ssl-validation
uaac token owner get opsman $OPS_MGR_USR -s "" -p $OPS_MGR_PWD
UAA_ACCESS_TOKEN=`cat ~/.uaac.yml | grep "access_token" | tr -d ":" -f2`

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
  "icmp_checks_enabled": false,
  "networks": [
    {
      "name": "$NETWORK_NAME",
      "service_network": false,
      "iaas_identifier": "$VCENTER_NETWORK",
      "subnets": [
        {
          "cidr": "$DEPLOYMENT_NW_CIDR",
          "reserved_ip_ranges": "$EXCLUDED_RANGE",
          "dns": "$DEPLOYMENT_NW_DNS",
          "gateway": "$DEPLOYMENT_NW_GATEWAY",
          "availability_zones": [
            "$AZ_1",
            "$AZ_2",
            "$AZ_3"
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
  "blobstore_type": "local"
}
EOF
)

NETWORK_ASSIGNMENT=$(cat <<-EOF
{
  "singleton_availability_zone": "$AZ_1",
  "network": "$NETWORK_NAME"
}
EOF
)

om -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-bosh \
            -i "$IAAS_CONFIGURATION" \
            -d "$DIRECTOR_CONFIG" \
            -n "$NETWORK_CONFIGURATION"

curl "https://example.com/api/v0/staged/director/availability_zones" \
            -X PUT \
            -H "Authorization: Bearer $UAA_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$AZ_CONFIGURATION"

om -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-bosh -na "$NETWORK_ASSIGNMENT"

#om -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD apply-changes
