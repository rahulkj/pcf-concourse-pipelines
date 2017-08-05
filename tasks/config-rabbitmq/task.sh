#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux


PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".properties.metrics_polling_interval": {
    "value": "$METRICS_POLLING_INTERVAL"
  },
  ".properties.disk_alarm_threshold": {
    "value": "$DISK_ALARM_THRESHOLD"
  },
  ".rabbitmq-server.plugins": {
    "value": [
      $RMQ_PLUGINS
    ]
  },
  ".rabbitmq-server.rsa_certificate": {
    "value": {
      "cert_pem":"$RMQ_SSL_CERT",
      "private_key_pem": "$RMQ_PRIVATE_CERT"
    }
  },
  ".rabbitmq-server.ssl_cacert": {
    "value": "$RMQ_CA_CERT"
  },
  ".rabbitmq-server.ssl_verify": {
    "value": "$SSL_VERIFY"
  },
  ".rabbitmq-server.ssl_verification_depth": {
    "value": "$SSL_VERIFICATION_DEPTH"
  },
  ".rabbitmq-server.ssl_fail_if_no_peer_cert": {
    "value": "$SSL_FAIL_IF_NO_PEER_CERT"
  },
  ".rabbitmq-server.cookie": {
    "value": "$ERLANG_COOKIE_NAME"
  },
  ".rabbitmq-server.config": {
    "value": "$RMQ_SERVER_CONFIG"
  },
  ".rabbitmq-server.security_options": {
    "value": "$RMQ_SECURITY_OPTION"
  },
  ".rabbitmq-server.cluster_partition_handling": {
    "value": "$RMQ_NW_PARTITION_HANDLING"
  },
  ".rabbitmq-server.ports": {
    "value": "$RMQ_SERVER_PORTS"
  },
  ".rabbitmq-server.static_ips": {
    "value": "$RMQ_SERVER_STATIC_IPS"
  },
  ".rabbitmq-haproxy.static_ips": {
    "value": "$RMQ_HAPROXY_STATIC_IPS"
  },
  ".rabbitmq-server.server_admin_credentials": {
    "value": {
      "identity": "$RMQ_ADMIN_USERNAME",
      "password": "$RMQ_ADMIN_PASSWORD"
    }
  },
  ".rabbitmq-broker.dns_host": {
    "value": "$RMQ_LOADBALANCER_DNS"
  },
  ".rabbitmq-broker.operator_set_policy_enabled": {
    "value": "$IS_RMQ_POLICY_ENABLED"
  },
  ".rabbitmq-broker.policy_definition": {
    "value": "$RMQ_POLICY_DEFINITION"
  },
  ".on-demand-broker.enable_single_node_plan": {
    "value": "$ENABLE_SINGLE_NODE_PLAN"
  },
  ".on-demand-broker.plan_name": {
    "value": "$PLAN_NAME"
  },
  ".on-demand-broker.plan_description": {
    "value": "$PLAN_DESCRIPTION"
  },
  ".on-demand-broker.plan_features": {
    "value": "$PCF_MARKETPLACE_PRODUCT_IDENTIFIER"
  },
  ".on-demand-broker.solo_plan_instance_quota": {
    "value": "$SERVICE_INSTANCE_COUNT"
  },
  ".on-demand-broker.global_service_instance_quota": {
    "value": "$GLOBAL_SERVICE_INSTANCE_QUOTA"
  },
  ".on-demand-broker.persistent_disk_type": {
    "value": "$SINGLE_NODE_PERSISTENT_DISK_TYPE"
  },
  ".on-demand-broker.az_placement": {
    "value": [
      "$ON_DEMAND_BROKER_AZS"
    ]
  },
  ".on-demand-broker.rmq_vm_type": {
    "value": "$ON_DEMAND_BROKER_VM_TYPE"
  },
  ".on-demand-broker.vm_extensions": {
    "value": "$VM_EXTENSIONS"
  }
}
EOF
)


#null|public_ip

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PRODUCT_NETWORK_CONFIG=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $BALANCE_JOB_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  },
  "service_network": {
    "name": "$SERVICES_NETWORK"
  }
}
EOF
)

PRODUCT_RESOURCE_CONFIG=$(cat <<-EOF
{
  "rabbitmq-server": {
    "instance_type": {"id": "automatic"},
    "instances": $RMQ_SERVER_INSTANCES,
    "persistent_disk": {"size_mb":"$RMQ_SERVER_NODE_PERSISTENT_DISK_SIZE"}
  },
  "rabbitmq-haproxy": {
    "instance_type": {"id": "automatic"},
    "instances": $RMQ_HAPROXY_INSTANCES
  },
  "rabbitmq-broker": {
    "instance_type": {"id": "automatic"},
    "instances": $RMQ_BROKER_INSTANCES
  },
  "on-demand-broker": {
    "instance_type": {"id": "automatic"},
    "instances": $RMQ_ONDEMAND_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG" -p "$PRODUCT_PROPERTIES" -pr "$PRODUCT_RESOURCE_CONFIG"

if [[ "$SYSLOG_SELECTOR" == "enabled" ]]; then
SYSLOG_PROPERTIES=$(cat <<-EOF
{
  ".properties.syslog_selector": {
    "value": "$SYSLOG_SELECTOR"
  },
  ".properties.syslog_selector.enabled.address": {
    "value": "$SYSLOG_ADDRESS"
  },
  ".properties.syslog_selector.enabled.port": {
    "value": "$SYSLOG_PORT"
  }
}
EOF
)
elif [[ "$SYSLOG_SELECTOR" == "disabled" ]]; then
SYSLOG_PROPERTIES=$(cat <<-EOF
{
  ".properties.syslog_selector": {
    "value": "$SYSLOG_SELECTOR"
  }
}
EOF
)
fi

echo "Configuring syslog ..."
$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$SYSLOG_PROPERTIES"
