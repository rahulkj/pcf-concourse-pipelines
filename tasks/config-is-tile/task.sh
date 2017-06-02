#!/bin/bash -e

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

if [[ -z "$SSL_CERT" ]]; then
DOMAINS=$(cat <<-EOF
  {"domains": ["*.$ISOLATION_SEGMENT_DOMAIN"] }
EOF
)

  CERTIFICATES=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS"`

  export SSL_CERT=`echo $CERTIFICATES | jq '.certificate' | tr -d '"'`
  export SSL_PRIVATE_KEY=`echo $CERTIFICATES | jq '.key' | tr -d '"'`

  echo "Using self signed certificates generated using Ops Manager..."

fi

PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".isolated_router.static_ips": {
    "value": "$ROUTER_STATIC_IPS"
  },
  ".isolated_diego_cell.executor_disk_capacity": {
    "value": "$CELL_DISK_CAPACITY"
  },
  ".isolated_diego_cell.executor_memory_capacity": {
    "value": "$CELL_MEMORY_CAPACITY"
  },
  ".isolated_diego_cell.garden_network_pool": {
    "value": "$APPLICATION_NETWORK_CIDR"
  },
  ".isolated_diego_cell.garden_network_mtu": {
    "value": $APPLICATION_NETWORK_MTU
  },
  ".isolated_diego_cell.insecure_docker_registry_list": {
    "value": "$INSECURE_DOCKER_REGISTRY_LIST"
  },
  ".isolated_diego_cell.placement_tag": {
    "value": "$SEGMENT_NAME"
  }
}
EOF
)

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

OTHER_AZS=$(fn_other_azs $DEPLOYMENT_NW_AZS)

PRODUCT_NETWORK_CONFIG=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $OTHER_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

PRODUCT_RESOURCE_CONFIG=$(cat <<-EOF
{
  "isolated_router": {
    "instance_type": {"id": "$ISOLATED_ROUTER_INSTANCE_TYPE"},
    "instances" : $IS_ROUTER_INSTANCES
  },
  "isolated_diego_cell": {
    "instance_type": {"id": "$DIEGO_CELL_INSTANCE_TYPE"},
    "instances" : $IS_DIEGO_CELL_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$PRODUCT_PROPERTIES" -pn "$PRODUCT_NETWORK_CONFIG" -pr "$PRODUCT_RESOURCE_CONFIG"

if [[ "$SSL_TERMINATION_POINT" == "terminate_at_router" ]]; then
echo "Terminating SSL at the gorouters and using self signed/provided certs..."
SSL_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "$SSL_TERMINATION_POINT"
  },
  ".properties.networking_point_of_entry.terminate_at_router.ssl_rsa_certificate": {
    "value": {
      "cert_pem": "$SSL_CERT",
      "private_key_pem": "$SSL_PRIVATE_KEY"
    }
  },
  ".properties.networking_point_of_entry.terminate_at_router.ssl_ciphers": {
    "value": "$ROUTER_SSL_CIPHERS"
  }
}
EOF
)

elif [[ "$SSL_TERMINATION_POINT" == "terminate_at_router_ert_cert" ]]; then
echo "Terminating SSL at the gorouters and reusing self signed/provided certs from ERT tile..."
SSL_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "$SSL_TERMINATION_POINT"
  }
}
EOF
)

elif [[ "$SSL_TERMINATION_POINT" == "terminate_before_router" ]]; then
echo "Unencrypted traffic to goRouters as SSL terminated at load balancer..."
SSL_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "$SSL_TERMINATION_POINT"
  }
}
EOF
)

fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$SSL_PROPERTIES"
