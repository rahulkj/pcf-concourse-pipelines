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

if [[ -z "$NETWORKING_POE_SSL_CERT_PEM" ]]; then
  DOMAINS=$(echo $ISOLATION_SEGMENT_DOMAINS | jq --raw-input -c '{"domains": (. | split(" "))}')

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "/api/v0/certificates/generate" -x POST -d "$DOMAINS"`

  export NETWORKING_POE_SSL_NAME="GENERATED-CERTS"
  export NETWORKING_POE_SSL_CERT_PEM=`echo $CERTIFICATES | jq --raw-output '.certificate'`
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=`echo $CERTIFICATES | jq --raw-output '.key'`

  echo "Using self signed certificates generated using Ops Manager..."
elif [[ "$NETWORKING_POE_SSL_CERT_PEM" =~ "\\r" ]]; then
  echo "No tweaking needed"
else
  export NETWORKING_POE_SSL_CERT_PEM=$(echo "$NETWORKING_POE_SSL_CERT_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\n",$0;}')
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=$(echo "$NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\n",$0;}')
fi

common_properties=$($JQ_CMD -n \
--arg enable_grootfs "${ENABLE_GROOTFS:-true}" \
--arg garden_disk_cleanup "${GARDEN_DISK_CLEANUP:-"threshold"}" \
--arg gorouter_ssl_ciphers "${GOROUTER_SSL_CIPHERS:-"ECDHE-RSA-AES128-GCM-SHA256:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"}" \
--arg haproxy_forward_tls "${HAPROXY_FORWARD_TLS:-"enable"}" \
--arg haproxy_forward_tls_enable_backend_ca "${HAPROXY_FORWARD_TLS_ENABLE_BACKEND_CA}" \
--arg haproxy_max_buffer_size "${HAPROXY_MAX_BUFFER_SIZE:-16384}" \
--arg haproxy_ssl_ciphers "${HAPROXY_SSL_CIPHERS:-"DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384"}" \
--arg networking_poe_ssl_name "${NETWORKING_POE_SSL_NAME}" \
--arg networking_poe_ssl_cert_pem "${NETWORKING_POE_SSL_CERT_PEM}" \
--arg networking_poe_ssl_cert_private_key_pem "${NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM}" \
--arg nfs_volume_driver "${NFS_VOLUME_DRIVER:-"enable"}" \
--arg nfs_volume_driver_enable_ldap_server_host "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVER_HOST}" \
--arg nfs_volume_driver_enable_ldap_server_port "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVER_PORT}" \
--arg nfs_volume_driver_enable_ldap_service_account_password "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVICE_ACCOUNT_PASSWORD}" \
--arg nfs_volume_driver_enable_ldap_service_account_user "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVICE_ACCOUNT_USER}" \
--arg nfs_volume_driver_enable_ldap_user_fqdn "${NFS_VOLUME_DRIVER_ENABLE_LDAP_USER_FQDN}" \
--arg router_backend_max_conn "${ROUTER_BACKEND_MAX_CONN:-500}" \
--arg router_client_cert_validation "${ROUTER_CLIENT_CERT_VALIDATION:-"request"}" \
--arg router_enable_proxy "${ROUTER_ENABLE_PROXY:-false}" \
--arg routing_custom_ca_certificates "${ROUTING_CUSTOM_CA_CERTIFICATES}" \
--arg routing_disable_http "${ROUTING_DISABLE_HTTP:-false}" \
--arg routing_minimum_tls_version "${ROUTING_MINIMUM_TLS_VERSION:-"tls_v1_2"}" \
--arg routing_table_sharding_mode "${ROUTING_TABLE_SHARDING_MODE:-"isolation_segment_only"}" \
--arg routing_tls_termination "${ROUTING_TLS_TERMINATION:-"load_balancer"}" \
--arg skip_cert_verify "${SKIP_CERT_VERIFY:-false}" \
--arg system_logging "${SYSTEM_LOGGING:-"disabled"}" \
--arg system_logging_enabled_host "${SYSTEM_LOGGING_ENABLED_HOST}" \
--arg system_logging_enabled_port "${SYSTEM_LOGGING_ENABLED_PORT}" \
--arg system_logging_enabled_protocol "${SYSTEM_LOGGING_ENABLED_PROTOCOL}" \
--arg system_logging_enabled_syslog_rule "${SYSTEM_LOGGING_ENABLED_SYSLOG_RULE}" \
--arg system_logging_enabled_tls_ca_cert "${SYSTEM_LOGGING_ENABLED_TLS_CA_CERT}" \
--arg system_logging_enabled_tls_enabled "${SYSTEM_LOGGING_ENABLED_TLS_ENABLED:-false}" \
--arg system_logging_enabled_tls_permitted_peer "${SYSTEM_LOGGING_ENABLED_TLS_PERMITTED_PEER}" \
--arg system_logging_enabled_use_tcp_for_file_forwarding_local_transport "${SYSTEM_LOGGING_ENABLED_USE_TCP_FOR_FILE_FORWARDING_LOCAL_TRANSPORT:-false}" \
'{
  ".properties.nfs_volume_driver": {
    "value": $nfs_volume_driver
  },
  ".properties.nfs_volume_driver.enable.ldap_service_account_user": {
    "value": $nfs_volume_driver_enable_ldap_service_account_user
  },
  ".properties.nfs_volume_driver.enable.ldap_service_account_password": {
    "value": {
      "secret": $nfs_volume_driver_enable_ldap_service_account_password
    }
  },
  ".properties.nfs_volume_driver.enable.ldap_server_host": {
    "value": $nfs_volume_driver_enable_ldap_server_host
  },
  ".properties.nfs_volume_driver.enable.ldap_server_port": {
    "value": $nfs_volume_driver_enable_ldap_server_port
  },
  ".properties.nfs_volume_driver.enable.ldap_user_fqdn": {
    "value": $nfs_volume_driver_enable_ldap_user_fqdn
  },
  ".properties.garden_disk_cleanup": {
    "value": $garden_disk_cleanup
  },
  ".properties.enable_grootfs": {
    "value": $enable_grootfs
  },
  ".properties.system_logging": {
    "value": $system_logging
  }
}
+
if $system_logging == "enabled" then
{
  ".properties.system_logging.enabled.host": {
    "value": $system_logging_enabled_host
  },
  ".properties.system_logging.enabled.port": {
    "value": $system_logging_enabled_port
  },
  ".properties.system_logging.enabled.protocol": {
    "value": $system_logging_enabled_protocol
  },
  ".properties.system_logging.enabled.tls_enabled": {
    "value": $system_logging_enabled_tls_enabled
  },
  ".properties.system_logging.enabled.tls_permitted_peer": {
    "value": $system_logging_enabled_tls_permitted_peer
  },
  ".properties.system_logging.enabled.tls_ca_cert": {
    "value": $system_logging_enabled_tls_ca_cert
  },
  ".properties.system_logging.enabled.use_tcp_for_file_forwarding_local_transport": {
    "value": $system_logging_enabled_use_tcp_for_file_forwarding_local_transport
  },
  ".properties.system_logging.enabled.syslog_rule": {
    "value": $system_logging_enabled_syslog_rule
  }
}
else .
end
+
{
  ".properties.routing_table_sharding_mode": {
    "value": $routing_table_sharding_mode
  },
  ".properties.networking_poe_ssl_certs": {
    "value": [
      {
        "name": $networking_poe_ssl_name,
        "certificate": {
          "cert_pem":$networking_poe_ssl_cert_pem,
          "private_key_pem":$networking_poe_ssl_cert_private_key_pem
        }
      }
    ]
  },
  ".properties.routing_custom_ca_certificates": {
    "value": $routing_custom_ca_certificates
  },
  ".properties.routing_disable_http": {
    "value": $routing_disable_http
  },
  ".properties.routing_minimum_tls_version": {
    "value": $routing_minimum_tls_version
  },
  ".properties.router_backend_max_conn": {
    "value": $router_backend_max_conn
  },
  ".properties.routing_tls_termination": {
    "value": $routing_tls_termination
  },
  ".properties.router_client_cert_validation": {
    "value": $router_client_cert_validation
  },
  ".properties.router_enable_proxy": {
    "value": $router_enable_proxy
  },
  ".properties.gorouter_ssl_ciphers": {
    "value": $gorouter_ssl_ciphers
  },
  ".properties.haproxy_ssl_ciphers": {
    "value": $haproxy_ssl_ciphers
  },
  ".properties.haproxy_max_buffer_size": {
    "value": $haproxy_max_buffer_size
  },
  ".properties.haproxy_forward_tls": {
    "value": $haproxy_forward_tls
  }
}
+
if $haproxy_forward_tls == "enable" then
{
  ".properties.haproxy_forward_tls.enable.backend_ca": {
    "value": $haproxy_forward_tls_enable_backend_ca
  }
}
else .
end
+
{
  ".properties.skip_cert_verify": {
    "value": $skip_cert_verify
  }
}'
)

if [[ -z "$REPLICATOR_NAME" ]]; then
additional_properties=$($JQ_CMD -n \
  --arg isolated_diego_cell_executor_disk_capacity "${ISOLATED_DIEGO_CELL_EXECUTOR_DISK_CAPACITY}" \
  --arg isolated_diego_cell_executor_memory_capacity "${ISOLATED_DIEGO_CELL_EXECUTOR_MEMORY_CAPACITY}" \
  --arg isolated_diego_cell_insecure_docker_registry_list "${ISOLATED_DIEGO_CELL_INSECURE_DOCKER_REGISTRY_LIST}" \
  --arg isolated_diego_cell_placement_tag "${ISOLATED_DIEGO_CELL_PLACEMENT_TAG}" \
  --arg isolated_ha_proxy_internal_only_domains "${ISOLATED_HA_PROXY_INTERNAL_ONLY_DOMAINS}" \
  --arg isolated_ha_proxy_static_ips "${ISOLATED_HA_PROXY_STATIC_IPS}" \
  --arg isolated_ha_proxy_trusted_domain_cidrs "${ISOLATED_HA_PROXY_TRUSTED_DOMAIN_CIDRS}" \
  --arg isolated_router_disable_insecure_cookies "${ISOLATED_ROUTER_DISABLE_INSECURE_COOKIES:-false}" \
  --arg isolated_router_drain_wait "${ISOLATED_ROUTER_DRAIN_WAIT:-20}" \
  --arg isolated_router_enable_write_access_logs "${ISOLATED_ROUTER_ENABLE_WRITE_ACCESS_LOGS:-true}" \
  --arg isolated_router_enable_zipkin "${ISOLATED_ROUTER_ENABLE_ZIPKIN:-true}" \
  --arg isolated_router_extra_headers_to_log "${ISOLATED_ROUTER_EXTRA_HEADERS_TO_LOG}" \
  --arg isolated_router_lb_healthy_threshold "${ISOLATED_ROUTER_LB_HEALTHY_THRESHOLD:-20}" \
  --arg isolated_router_request_timeout_in_seconds "${ISOLATED_ROUTER_REQUEST_TIMEOUT_IN_SECONDS:-900}" \
  --arg isolated_router_static_ips "${ISOLATED_ROUTER_STATIC_IPS}" \
  '
  {
    ".isolated_ha_proxy.static_ips": {
      "value": $isolated_ha_proxy_static_ips
    },
    ".isolated_ha_proxy.internal_only_domains": {
      "value": $isolated_ha_proxy_internal_only_domains
    },
    ".isolated_ha_proxy.trusted_domain_cidrs": {
      "value": $isolated_ha_proxy_trusted_domain_cidrs
    },
    ".isolated_router.static_ips": {
      "value": $isolated_router_static_ips
    },
    ".isolated_router.disable_insecure_cookies": {
      "value": $isolated_router_disable_insecure_cookies
    },
    ".isolated_router.enable_zipkin": {
      "value": $isolated_router_enable_zipkin
    },
    ".isolated_router.enable_write_access_logs": {
      "value": $isolated_router_enable_write_access_logs
    },
    ".isolated_router.request_timeout_in_seconds": {
      "value": $isolated_router_request_timeout_in_seconds
    },
    ".isolated_router.extra_headers_to_log": {
      "value": $isolated_router_extra_headers_to_log
    },
    ".isolated_router.drain_wait": {
      "value": $isolated_router_drain_wait
    },
    ".isolated_router.lb_healthy_threshold": {
      "value": $isolated_router_lb_healthy_threshold
    },
    ".isolated_diego_cell.executor_disk_capacity": {
      "value": $isolated_diego_cell_executor_disk_capacity
    },
    ".isolated_diego_cell.executor_memory_capacity": {
      "value": $isolated_diego_cell_executor_memory_capacity
    },
    ".isolated_diego_cell.insecure_docker_registry_list": {
      "value": $isolated_diego_cell_insecure_docker_registry_list
    },
    ".isolated_diego_cell.placement_tag": {
      "value": $isolated_diego_cell_placement_tag
    }
  }
  '
)

resources_config="{
  \"isolated_ha_proxy\": {\"instances\": ${ISOLATED_HA_PROXY_INSTANCES:-3}, \"instance_type\": { \"id\": \"${ISOLATED_HA_PROXY_INSTANCE_TYPE:-micro}\"}},
  \"isolated_router\": {\"instances\": ${ISOLATED_ROUTER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${ISOLATED_ROUTER_INSTANCE_TYPE:-micro}\"}},
  \"isolated_diego_cell\": {\"instances\": ${ISOLATED_DIEGO_CELL_INSTANCES:-3}, \"instance_type\": { \"id\": \"${ISOLATED_DIEGO_CELL_INSTANCE_TYPE:-xlarge.disk}\"}}
}"

else

additional_properties=$(cat <<-EOF
{
  ".isolated_ha_proxy_$REPLICATOR_NAME.static_ips": {
    "value": "$ISOLATED_HA_PROXY_STATIC_IPS"
  },
  ".isolated_ha_proxy_$REPLICATOR_NAME.internal_only_domains": {
    "value": "$ISOLATED_HA_PROXY_INTERNAL_ONLY_DOMAINS"
  },
  ".isolated_ha_proxy_$REPLICATOR_NAME.trusted_domain_cidrs": {
    "value": "$ISOLATED_HA_PROXY_TRUSTED_DOMAIN_CIDRS"
  },
  ".isolated_router_$REPLICATOR_NAME.static_ips": {
    "value": "$ISOLATED_ROUTER_STATIC_IPS"
  },
  ".isolated_router_$REPLICATOR_NAME.disable_insecure_cookies": {
    "value": "$ISOLATED_ROUTER_DISABLE_INSECURE_COOKIES"
  },
  ".isolated_router_$REPLICATOR_NAME.enable_zipkin": {
    "value": "$ISOLATED_ROUTER_ENABLE_ZIPKIN"
  },
  ".isolated_router_$REPLICATOR_NAME.enable_write_access_logs": {
    "value": "$ISOLATED_ROUTER_ENABLE_WRITE_ACCESS_LOGS"
  },
  ".isolated_router_$REPLICATOR_NAME.request_timeout_in_seconds": {
    "value": "$ISOLATED_ROUTER_REQUEST_TIMEOUT_IN_SECONDS"
  },
  ".isolated_router_$REPLICATOR_NAME.extra_headers_to_log": {
    "value": "$ISOLATED_ROUTER_EXTRA_HEADERS_TO_LOG"
  },
  ".isolated_router_$REPLICATOR_NAME.drain_wait": {
    "value": "$ISOLATED_ROUTER_DRAIN_WAIT"
  },
  ".isolated_router_$REPLICATOR_NAME.lb_healthy_threshold": {
    "value": "$ISOLATED_ROUTER_LB_HEALTHY_THRESHOLD"
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.executor_disk_capacity": {
    "value": "$ISOLATED_DIEGO_CELL_EXECUTOR_DISK_CAPACITY"
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.executor_memory_capacity": {
    "value": "$ISOLATED_DIEGO_CELL_EXECUTOR_MEMORY_CAPACITY"
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.insecure_docker_registry_list": {
    "value": "$ISOLATED_DIEGO_CELL_INSECURE_DOCKER_REGISTRY_LIST"
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.placement_tag": {
    "value": "$ISOLATED_DIEGO_CELL_PLACEMENT_TAG"
  }
}
EOF
)

resources_config="{
  \"isolated_ha_proxy_$REPLICATOR_NAME\": {\"instances\": ${ISOLATED_HA_PROXY_INSTANCES:-3}, \"instance_type\": { \"id\": \"${ISOLATED_HA_PROXY_INSTANCE_TYPE:-micro}\"}},
  \"isolated_router_$REPLICATOR_NAME\": {\"instances\": ${ISOLATED_ROUTER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${ISOLATED_ROUTER_INSTANCE_TYPE:-micro}\"}},
  \"isolated_diego_cell_$REPLICATOR_NAME\": {\"instances\": ${ISOLATED_DIEGO_CELL_INSTANCES:-3}, \"instance_type\": { \"id\": \"${ISOLATED_DIEGO_CELL_INSTANCE_TYPE:-xlarge.disk}\"}}
}"
fi

echo "$additional_properties" > additional_properties.json
echo "$common_properties" > common_properties.json

properties_config=$($JQ_CMD -s add common_properties.json additional_properties.json)

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
  --product-name $PRODUCT_IDENTIFIER \
  --product-properties "$properties_config" \
  --product-network "$network_config" \
  --product-resources "$resources_config"
