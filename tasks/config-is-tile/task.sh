#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

if [[ -z "$NETWORKING_POE_SSL_CERT_PEM" ]]; then
DOMAINS=$(cat <<-EOF
  {"domains": $ISOLATION_SEGMENT_DOMAINS }
EOF
)

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS"`

  export NETWORKING_POE_SSL_NAME="GENERATED-CERTS"
  export NETWORKING_POE_SSL_CERT_PEM=`echo $CERTIFICATES | jq --raw-output '.certificate'`
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=`echo $CERTIFICATES | jq --raw-output '.key'`

  echo "Using self signed certificates generated using Ops Manager..."
elif [[ "$NETWORKING_POE_SSL_CERT_PEM" =~ "\\r" ]]; then
  echo "No tweaking needed"
else
  export NETWORKING_POE_SSL_CERT_PEM=$(echo "$NETWORKING_POE_SSL_CERT_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=$(echo "$NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
fi

common_properties_config=$($JQ_CMD -n \
  --arg container_networking $CONTAINER_NETWORKING \
  --arg enable_grootfs $ENABLE_GROOTFS \
  --arg garden_disk_cleanup $GARDEN_DISK_CLEANUP \
  --arg gorouter_ssl_ciphers $GOROUTER_SSL_CIPHERS \
  --arg haproxy_forward_tls $HAPROXY_FORWARD_TLS \
  --arg backend_ca $BACKEND_CA \
  --arg haproxy_max_buffer_size $HAPROXY_MAX_BUFFER_SIZE \
  --arg haproxy_ssl_ciphers $HAPROXY_SSL_CIPHERS \
  --arg networking_poe_ssl_name $NETWORKING_POE_SSL_NAME \
  --arg networking_poe_ssl_cert_pem $NETWORKING_POE_SSL_CERT_PEM \
  --arg networking_poe_ssl_cert_private_key_pem $NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM \
  --arg networking_point_of_entry $NETWORKING_POINT_OF_ENTRY \
  --arg nfs_volume_driver $NFS_VOLUME_DRIVER \
  --arg ldap_server_host $LDAP_SERVER_HOST \
  --arg ldap_server_port $LDAP_SERVER_PORT \
  --arg ldap_service_account_password $LDAP_SERVICE_ACCOUNT_PASSWORD \
  --arg ldap_service_account_user $LDAP_SERVICE_ACCOUNT_USER \
  --arg ldap_user_fqdn $LDAP_USER_FQDN \
  --arg router_backend_max_conn $ROUTER_BACKEND_MAX_CONN \
  --arg router_client_cert_validation $ROUTER_CLIENT_CERT_VALIDATION \
  --arg routing_custom_ca_certificates $ROUTING_CUSTOM_CA_CERTIFICATES \
  --arg routing_disable_http $ROUTING_DISABLE_HTTP \
  --arg routing_minimum_tls_version $ROUTING_MINIMUM_TLS_VERSION \
  --arg routing_table_sharding_mode $ROUTING_TABLE_SHARDING_MODE \
  --arg routing_tls_termination $ROUTING_TLS_TERMINATION \
  --arg skip_cert_verify $SKIP_CERT_VERIFY \
  --arg system_logging $SYSTEM_LOGGING \
  --arg syslog_host $SYSLOG_HOST \
  --arg syslog_port $SYSLOG_PORT \
  --arg syslog_protocol $SYSLOG_PROTOCOL \
  --arg syslog_rule $SYSLOG_RULE \
  --arg syslog_tls_ca_cert $SYSLOG_TLS_CA_CERT \
  --arg syslog_tls_enabled $SYSLOG_TLS_ENABLED \
  --arg syslog_tls_permitted_peer $SYSLOG_TLS_PERMITTED_PEER \
  --arg syslog_use_tcp_for_file_forwarding_local_transport $SYSLOG_USE_TCP_FOR_FILE_FORWARDING_LOCAL_TRANSPORT \
'{
  ".properties.nfs_volume_driver": {
    "value": $nfs_volume_driver
  }
  +
  if $nfs_volume_driver == "enable" then
  {
    ".properties.nfs_volume_driver.enable.ldap_service_account_user": {
      "value": $ldap_service_account_user
    },
    ".properties.nfs_volume_driver.enable.ldap_service_account_password": {
      "secret": {
        "value": $ldap_service_account_password
      }
    },
    ".properties.nfs_volume_driver.enable.ldap_server_host": {
      "value": $ldap_server_host
    },
    ".properties.nfs_volume_driver.enable.ldap_server_port": {
      "value": $ldap_server_port
    },
    ".properties.nfs_volume_driver.enable.ldap_user_fqdn": {
      "value": $ldap_user_fqdn
    }
  }
  else .
  end
  +
  {
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
      "value": $syslog_host
    },
    ".properties.system_logging.enabled.port": {
      "value": $syslog_port
    },
    ".properties.system_logging.enabled.protocol": {
      "value": $syslog_protocol
    },
    ".properties.system_logging.enabled.tls_enabled": {
      "value": $syslog_tls_enabled
    },
    ".properties.system_logging.enabled.tls_permitted_peer": {
      "value": $syslog_tls_permitted_peer
    },
    ".properties.system_logging.enabled.tls_ca_cert": {
      "value": $syslog_tls_ca_cert
    },
    ".properties.system_logging.enabled.use_tcp_for_file_forwarding_local_transport": {
      "value": $syslog_use_tcp_for_file_forwarding_local_transport
    },
    ".properties.system_logging.enabled.syslog_rule": {
      "value": $syslog_rule
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
      "value": $backend_ca
    }
  }
  else .
  end
  +
  {
    ".properties.container_networking": {
      "value": $container_networking
    },
    ".properties.skip_cert_verify": {
      "value": $skip_cert_verify
    },
    ".properties.networking_point_of_entry": {
      "value": $networking_point_of_entry
    }
  }
}'
)

if [[ -z "$REPLICATOR_NAME" ]]; then
additional_properties_config=$($JQ_CMD -n \
  --arg ha_proxy_static_ips $HA_PROXY_STATIC_IPS \
  --arg internal_only_domains $INTERNAL_ONLY_DOMAINS \
  --arg trusted_domain_cidrs $TRUSTED_DOMAIN_CIDRS \
  --arg router_static_ips $ROUTER_STATIC_IPS \
  --arg disable_insecure_cookies $DISABLE_INSECURE_COOKIES \
  --arg enable_zipkin $ENABLE_ZIPKIN \
  --arg enable_write_access_logs $ENABLE_WRITE_ACCESS_LOGS \
  --arg request_timeout_in_seconds $REQUEST_TIMEOUT_IN_SECONDS \
  --arg max_idle_connections $MAX_IDLE_CONNECTIONS \
  --arg extra_headers_to_log $EXTRA_HEADERS_TO_LOG \
  --arg drain_wait $DRAIN_WAIT \
  --arg lb_healthy_threshold $LB_HEALTHY_THRESHOLD \
  --arg executor_disk_capacity $EXECUTOR_DISK_CAPACITY \
  --arg executor_memory_capacity $EXECUTOR_MEMORY_CAPACITY \
  --arg insecure_docker_registry_list $INSECURE_DOCKER_REGISTRY_LIST \
  --arg placement_tag $PLACEMENT_TAG \
  '
  {
    ".isolated_ha_proxy.static_ips": {
      "value": $ha_proxy_static_ips
    },
    ".isolated_ha_proxy.internal_only_domains": {
      "value": $internal_only_domains
    },
    ".isolated_ha_proxy.trusted_domain_cidrs": {
      "value": $trusted_domain_cidrs
    },
    ".isolated_router.static_ips": {
      "value": $router_static_ips
    },
    ".isolated_router.disable_insecure_cookies": {
      "value": $disable_insecure_cookies
    },
    ".isolated_router.enable_zipkin": {
      "value": $enable_zipkin
    },
    ".isolated_router.enable_write_access_logs": {
      "value": $enable_write_access_logs
    },
    ".isolated_router.request_timeout_in_seconds": {
      "value": $request_timeout_in_seconds
    },
    ".isolated_router.max_idle_connections": {
      "value": $max_idle_connections
    },
    ".isolated_router.extra_headers_to_log": {
      "value": $extra_headers_to_log
    },
    ".isolated_router.drain_wait": {
      "value": $drain_wait
    },
    ".isolated_router.lb_healthy_threshold": {
      "value": $lb_healthy_threshold
    },
    ".isolated_diego_cell.executor_disk_capacity": {
      "value": $executor_disk_capacity
    },
    ".isolated_diego_cell.executor_memory_capacity": {
      "value": $executor_memory_capacity
    },
    ".isolated_diego_cell.insecure_docker_registry_list": {
      "value": $insecure_docker_registry_list
    },
    ".isolated_diego_cell.placement_tag": {
      "value": $placement_tag
    }
  }
  '
)

resources_config="{
  \"isolated_ha_proxy\": {\"instances\": $ISOLATED_HA_PROXY_INSTANCES},
  \"isolated_router\": {\"instances\": $ISOLATED_ROUTER_INSTANCES},
  \"isolated_diego_cell\": {\"instances\": $ISOLATED_DIEGO_CELL_INSTANCES},
}"
else
additional_properties_config=$(cat <<-EOF
{
  ".isolated_ha_proxy_$REPLICATOR_NAME.static_ips": {
    "value": $HA_PROXY_STATIC_IPS
  },
  ".isolated_ha_proxy_$REPLICATOR_NAME.internal_only_domains": {
    "value": $INTERNAL_ONLY_DOMAINS
  },
  ".isolated_ha_proxy_$REPLICATOR_NAME.trusted_domain_cidrs": {
    "value": $TRUSTED_DOMAIN_CIDRS
  },
  ".isolated_router_$REPLICATOR_NAME.static_ips": {
    "value": $ROUTER_STATIC_IPS
  },
  ".isolated_router_$REPLICATOR_NAME.disable_insecure_cookies": {
    "value": $DISABLE_INSECURE_COOKIES
  },
  ".isolated_router_$REPLICATOR_NAME.enable_zipkin": {
    "value": $ENABLE_ZIPKIN
  },
  ".isolated_router_$REPLICATOR_NAME.enable_write_access_logs": {
    "value": $ENABLE_WRITE_ACCESS_LOGS
  },
  ".isolated_router_$REPLICATOR_NAME.request_timeout_in_seconds": {
    "value": $REQUEST_TIMEOUT_IN_SECONDS
  },
  ".isolated_router_$REPLICATOR_NAME.max_idle_connections": {
    "value": $MAX_IDLE_CONNECTIONS
  },
  ".isolated_router_$REPLICATOR_NAME.extra_headers_to_log": {
    "value": $EXTRA_HEADERS_TO_LOG
  },
  ".isolated_router_$REPLICATOR_NAME.drain_wait": {
    "value": $DRAIN_WAIT
  },
  ".isolated_router_$REPLICATOR_NAME.lb_healthy_threshold": {
    "value": $LB_HEALTHY_THRESHOLD
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.executor_disk_capacity": {
    "value": $EXECUTOR_DISK_CAPACITY
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.executor_memory_capacity": {
    "value": $EXECUTOR_MEMORY_CAPACITY
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.insecure_docker_registry_list": {
    "value": $INSECURE_DOCKER_REGISTRY_LIST
  },
  ".isolated_diego_cell_$REPLICATOR_NAME.placement_tag": {
    "value": $PLACEMENT_TAG
  }
}
EOF
)

resources_config="{
  \"isolated_ha_proxy_$REPLICATOR_NAME\": {\"instances\": $ISOLATED_HA_PROXY_INSTANCES},
  \"isolated_router_$REPLICATOR_NAME\": {\"instances\": $ISOLATED_ROUTER_INSTANCES},
  \"isolated_diego_cell_$REPLICATOR_NAME\": {\"instances\": $ISOLATED_DIEGO_CELL_INSTANCES},
}"
fi

echo "$additional_properties_config" > additional_properties_config.json
echo "$common_properties_config" > common_properties_config.json

properties_config=$($JQ_CMD -s add additional_properties_config.json common_properties_config.json)


network_config=$($JQ_CMD -n \
  --arg network_name "$NETWORK_NAME" \
  --arg other_azs "$SERVICES_NW_AZS" \
  --arg singleton_az "$SERVICE_SINGLETON_JOB_AZ" \
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

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$properties_config" -pn "$network_config" -pr "$resources_config"
