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
  --arg on_demand_broker_global_service_instance_quota "${ON_DEMAND_BROKER_GLOBAL_SERVICE_INSTANCE_QUOTA:-20}" \
  --arg disk_alarm_threshold "${DISK_ALARM_THRESHOLD:-"mem_relative_1_5"}" \
  --arg metrics_polling_interval "${METRICS_POLLING_INTERVAL:-30}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR:-"disabled"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_cf_service_access "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_CF_SERVICE_ACCESS:-"enable"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_description "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_DESCRIPTION:-"This plan provides a preconfigured dedicated cluster of RabbitMQ nodes"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_disk_limit_acknowledgement "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_DISK_LIMIT_ACKNOWLEDGEMENT:-"non-existant-value"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_features "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_FEATURES:-"RabbitMQ"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_instance_quota "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_INSTANCE_QUOTA:-0}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_name "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_NAME:-"cluster"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_az_placement "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_RABBITMQ_AZ_PLACEMENT}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_cluster_partition_handling_strategy "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_RABBITMQ_CLUSTER_PARTITION_HANDLING_STRATEGY:-"pause_minority"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_number_of_nodes "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_RABBITMQ_NUMBER_OF_NODES:-3}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_persistent_disk_type "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_RABBITMQ_PERSISTENT_DISK_TYPE:-"1024"}" \
  --arg on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_vm_type "${ON_DEMAND_BROKER_DEDICATED_CLUSTER_PLAN_SELECTOR_ENABLED_RABBITMQ_VM_TYPE:-"nano"}" \
  --arg on_demand_broker_dedicated_single_node_plan_cf_service_access "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_CF_SERVICE_ACCESS:-"disable"}" \
  --arg on_demand_broker_dedicated_single_node_plan_description "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_DESCRIPTION:-"This plan provides a single dedicated RabbitMQ node"}" \
  --arg on_demand_broker_dedicated_single_node_plan_disk_limit_acknowledgement "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_DISK_LIMIT_ACKNOWLEDGEMENT:-"non-existant-value"}" \
  --arg on_demand_broker_dedicated_single_node_plan_features "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_FEATURES:-"RabbitMQ"}" \
  --arg on_demand_broker_dedicated_single_node_plan_instance_quota "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_INSTANCE_QUOTA:-0}" \
  --arg on_demand_broker_dedicated_single_node_plan_name "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_NAME:-"solo"}" \
  --arg on_demand_broker_dedicated_single_node_plan_rabbitmq_az_placement "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_RABBITMQ_AZ_PLACEMENT}" \
  --arg on_demand_broker_dedicated_single_node_plan_rabbitmq_persistent_disk_type "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_RABBITMQ_PERSISTENT_DISK_TYPE:-"1024"}" \
  --arg on_demand_broker_dedicated_single_node_plan_rabbitmq_vm_type "${ON_DEMAND_BROKER_DEDICATED_SINGLE_NODE_PLAN_RABBITMQ_VM_TYPE:-"nano"}" \
  --arg on_demand_broker_vm_extensions "${ON_DEMAND_BROKER_VM_EXTENSIONS}" \
  --arg syslog_selector "${SYSLOG_SELECTOR:-"enabled"}" \
  --arg syslog_selector_enabled_address "${SYSLOG_SELECTOR_ENABLED_ADDRESS}" \
  --arg syslog_selector_enabled_port "${SYSLOG_SELECTOR_ENABLED_PORT}" \
  --arg syslog_selector_enabled_syslog_ca_cert "${SYSLOG_SELECTOR_ENABLED_SYSLOG_CA_CERT}" \
  --arg syslog_selector_enabled_syslog_format "${SYSLOG_SELECTOR_ENABLED_SYSLOG_FORMAT:-"rfc5424"}" \
  --arg syslog_selector_enabled_syslog_permitted_peer "${SYSLOG_SELECTOR_ENABLED_SYSLOG_PERMITTED_PEER}" \
  --arg syslog_selector_enabled_syslog_tls "${SYSLOG_SELECTOR_ENABLED_SYSLOG_TLS:-false}" \
  --arg syslog_selector_enabled_syslog_transport "${SYSLOG_SELECTOR_ENABLED_SYSLOG_TRANSPORT:-"tcp"}" \
  --arg rabbitmq_broker_dns_host "${RABBITMQ_BROKER_DNS_HOST}" \
  --arg rabbitmq_broker_operator_set_policy_enabled "${RABBITMQ_BROKER_OPERATOR_SET_POLICY_ENABLED:-false}" \
  --arg rabbitmq_broker_policy_definition "${RABBITMQ_BROKER_POLICY_DEFINITION}" \
  --arg rabbitmq_haproxy_static_ips ""${RABBITMQ_HAPROXY_STATIC_IPS}"" \
  --arg rabbitmq_server_cluster_partition_handling "${RABBITMQ_SERVER_CLUSTER_PARTITION_HANDLING:-"pause_minority"}" \
  --arg rabbitmq_server_config "${RABBITMQ_SERVER_CONFIG}" \
  --arg rabbitmq_server_cookie "${RABBITMQ_SERVER_COOKIE}" \
  --arg rabbitmq_server_plugins "${RABBITMQ_SERVER_PLUGINS:-'rabbitmq_management'}" \
  --arg rabbitmq_server_ports "${RABBITMQ_SERVER_PORTS:-"15672, 5672, 5671, 1883, 8883, 61613, 61614, 15674"}" \
  --arg rabbitmq_server_ssl_cert_pem "${RABBITMQ_SERVER_SSL_CERT_PEM}" \
  --arg rabbitmq_server_ssl_private_key_pem "${RABBITMQ_SERVER_SSL_PRIVATE_KEY_PEM}" \
  --arg rabbitmq_server_rsa_certificate "${RABBITMQ_SERVER_RSA_CERTIFICATE}" \
  --arg rabbitmq_server_server_admin_username "${RABBITMQ_SERVER_SERVER_ADMIN_USERNAME}" \
  --arg rabbitmq_server_server_admin_password "${RABBITMQ_SERVER_SERVER_ADMIN_PASSWORD}" \
  --arg rabbitmq_server_ssl_cacert "${RABBITMQ_SERVER_SSL_CACERT}" \
  --arg rabbitmq_server_ssl_fail_if_no_peer_cert "${RABBITMQ_SERVER_SSL_FAIL_IF_NO_PEER_CERT:-false}" \
  --arg rabbitmq_server_ssl_verification_depth "${RABBITMQ_SERVER_SSL_VERIFICATION_DEPTH:-5}" \
  --arg rabbitmq_server_ssl_verify "${RABBITMQ_SERVER_SSL_VERIFY:-false}" \
  --arg rabbitmq_server_ssl_versions "${RABBITMQ_SERVER_SSL_VERSIONS:-"tlsv1.1,tlsv1.2"}" \
  --arg rabbitmq_server_static_ips "${RABBITMQ_SERVER_STATIC_IPS:-""}" \
'{
  ".properties.metrics_polling_interval": {
    "value": $metrics_polling_interval
  },
  ".properties.syslog_selector": {
    "value": $syslog_selector
  }
}
+
if $syslog_selector == "enabled" then
{
  ".properties.syslog_selector.enabled.address": {
    "value": $syslog_selector_enabled_address
  },
  ".properties.syslog_selector.enabled.port": {
    "value": $syslog_selector_enabled_port
  },
  ".properties.syslog_selector.enabled.syslog_transport": {
    "value": $syslog_selector_enabled_syslog_transport
  },
  ".properties.syslog_selector.enabled.syslog_format": {
    "value": $syslog_selector_enabled_syslog_format
  },
  ".properties.syslog_selector.enabled.syslog_tls": {
    "value": $syslog_selector_enabled_syslog_tls
  },
  ".properties.syslog_selector.enabled.syslog_permitted_peer": {
    "value": $syslog_selector_enabled_syslog_permitted_peer
  },
  ".properties.syslog_selector.enabled.syslog_ca_cert": {
    "value": $syslog_selector_enabled_syslog_ca_cert
  }
}
else .
end
+
{
  ".properties.on_demand_broker_vm_extensions": {
    "value": $on_demand_broker_vm_extensions
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_cf_service_access": {
    "value": $on_demand_broker_dedicated_single_node_plan_cf_service_access
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_name": {
    "value": $on_demand_broker_dedicated_single_node_plan_name
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_description": {
    "value": $on_demand_broker_dedicated_single_node_plan_description
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_instance_quota": {
    "value": $on_demand_broker_dedicated_single_node_plan_instance_quota
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_features": {
    "value": $on_demand_broker_dedicated_single_node_plan_features
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_rabbitmq_az_placement": {
    "value": $on_demand_broker_dedicated_single_node_plan_rabbitmq_az_placement
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_rabbitmq_vm_type": {
    "value": $on_demand_broker_dedicated_single_node_plan_rabbitmq_vm_type
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_rabbitmq_persistent_disk_type": {
    "value": $on_demand_broker_dedicated_single_node_plan_rabbitmq_persistent_disk_type
  },
  ".properties.on_demand_broker_dedicated_single_node_plan_disk_limit_acknowledgement": {
    "value": $on_demand_broker_dedicated_single_node_plan_disk_limit_acknowledgement
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector
  }
}
+
if $on_demand_broker_dedicated_cluster_plan_selector == "enabled" then
{
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.cf_service_access": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_cf_service_access
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.name": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_name
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.description": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_description
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.features": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_features
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.instance_quota": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_instance_quota
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.rabbitmq_persistent_disk_type": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_persistent_disk_type
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.rabbitmq_number_of_nodes": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_number_of_nodes
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.rabbitmq_cluster_partition_handling_strategy": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_cluster_partition_handling_strategy
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.rabbitmq_az_placement": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_az_placement
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.rabbitmq_vm_type": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_rabbitmq_vm_type
  },
  ".properties.on_demand_broker_dedicated_cluster_plan_selector.enabled.disk_limit_acknowledgement": {
    "value": $on_demand_broker_dedicated_cluster_plan_selector_enabled_disk_limit_acknowledgement
  }
}
else .
end
+
{
  ".properties.disk_alarm_threshold": {
    "value": $disk_alarm_threshold
  },
  ".rabbitmq-server.server_admin_credentials": {
    "value": {
      "identity": $rabbitmq_server_server_admin_username,
      "password": $rabbitmq_server_server_admin_password
    }
  },
  ".rabbitmq-server.plugins": {
    "value": ( $rabbitmq_server_plugins | split(",") )
  },
  ".rabbitmq-server.rsa_certificate": {
    "value": {
      "cert_pem": $rabbitmq_server_ssl_cert_pem,
      "private_key_pem": $rabbitmq_server_ssl_private_key_pem
    }
  },
  ".rabbitmq-server.ssl_cacert": {
    "value": $rabbitmq_server_ssl_cacert
  },
  ".rabbitmq-server.ssl_verify": {
    "value": $rabbitmq_server_ssl_verify
  },
  ".rabbitmq-server.ssl_verification_depth": {
    "value": $rabbitmq_server_ssl_verification_depth
  },
  ".rabbitmq-server.ssl_fail_if_no_peer_cert": {
    "value": $rabbitmq_server_ssl_fail_if_no_peer_cert
  },
  ".rabbitmq-server.cookie": {
    "value": $rabbitmq_server_cookie
  },
  ".rabbitmq-server.config": {
    "value": $rabbitmq_server_config
  },
  ".rabbitmq-server.ssl_versions": {
    "value": ( $rabbitmq_server_ssl_versions | split(",") )
  },
  ".rabbitmq-server.cluster_partition_handling": {
    "value": $rabbitmq_server_cluster_partition_handling
  },
  ".rabbitmq-server.ports": {
    "value": $rabbitmq_server_ports
  },
  ".rabbitmq-server.static_ips": {
    "value": $rabbitmq_server_static_ips
  },
  ".rabbitmq-haproxy.static_ips": {
    "value": $rabbitmq_haproxy_static_ips
  },
  ".rabbitmq-broker.dns_host": {
    "value": $rabbitmq_broker_dns_host
  },
  ".rabbitmq-broker.operator_set_policy_enabled": {
    "value": $rabbitmq_broker_operator_set_policy_enabled
  },
  ".rabbitmq-broker.policy_definition": {
    "value": $rabbitmq_broker_policy_definition
  },
  ".on-demand-broker.global_service_instance_quota": {
    "value": $on_demand-broker_global_service_instance_quota
  }
}'
)

resources_config="{
  \"rabbitmq-server\": {\"instances\": ${RABBITMQ_SERVER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${RABBITMQ_SERVER_INSTANCE_TYPE:-large}\"}, \"persistent_disk\": { \"size_mb\": \"${RABBITMQ_SERVER_PERSISTENT_DISK_MB:-30720}\"}},
  \"rabbitmq-haproxy\": {\"instances\": ${RABBITMQ_HAPROXY_INSTANCES:-1}, \"instance_type\": { \"id\": \"${RABBITMQ_HAPROXY_INSTANCE_TYPE:-small}\"}},
  \"rabbitmq-broker\": {\"instances\": ${RABBITMQ_BROKER_INSTANCES:-1}, \"instance_type\": { \"id\": \"${RABBITMQ_BROKER_INSTANCE_TYPE:-small}\"}},
  \"on-demand-broker\": {\"instances\": ${ON_DEMAND_BROKER_INSTANCES:-1}, \"instance_type\": { \"id\": \"${ON_DEMAND_BROKER_INSTANCE_TYPE:-micro}\"}, \"persistent_disk\": { \"size_mb\": \"${ON_DEMAND_BROKER_PERSISTENT_DISK_MB:-1024}\"}}
}"

network_config=$($JQ_CMD -n \
  --arg network_name "$NETWORK_NAME" \
  --arg other_azs "$OTHER_AZS" \
  --arg singleton_az "$SINGLETON_JOBS_AZ" \
  --arg service_network_name "$SERVICE_NETWORK_NAME" \
'
  {
    "network": {
      "name": $network_name
    },
    "other_availability_zones": ($other_azs | split(",") | map({name: .})),
    "singleton_availability_zone": {
      "name": $singleton_az
    },
    "service_network": {
      "name": $service_network_name
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
  --product-name p-rabbitmq \
  --product-network "$network_config"

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name p-rabbitmq \
  --product-properties "$properties_config" \
  --product-resources "$resources_config"
