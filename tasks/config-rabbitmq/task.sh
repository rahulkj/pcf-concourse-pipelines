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

PRODUCT_NETWORK_CONFIG=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg singleton_jobs_az "$SINGLETON_JOBS_AZ" \
    --arg other_azs "$OTHER_AZS" \
    --arg network_name "$NETWORK_NAME" \
    --arg services_network_name "$SERVICES_NETWORK_NAME" \
    '. +
    {
      "singleton_availability_zone": {
        "name": $singleton_jobs_az
      },
      "other_availability_zones": ($other_azs | split(",") | map({name: .})),
      "network": {
        "name": $network_name
      },
      "service_network": {
        "name": $services_network_name
      }
    }
    '
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG"

PRODUCT_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --argjson metrics_polling_interval $METRICS_POLLING_INTERVAL \
    --arg syslog_selector "$SYSLOG_SELECTOR" \
    --arg syslog_selector_address "$SYSLOG_SELECTOR_ADDRESS" \
    --arg syslog_selector_port "$SYSLOG_SELECTOR_PORT" \
    --arg syslog_selector_syslog_transport "$SYSLOG_SELECTOR_SYSLOG_TRANSPORT" \
    --arg syslog_selector_syslog_format "$SYSLOG_SELECTOR_SYSLOG_FORMAT" \
    --argjson syslog_selector_syslog_tls $SYSLOG_SELECTOR_SYSLOG_TLS \
    --arg syslog_selector_syslog_permitted_peer "$SYSLOG_SELECTOR_SYSLOG_PERMITTED_PEER" \
    --arg syslog_selector_syslog_ca_cert "$SYSLOG_SELECTOR_SYSLOG_CA_CERT" \
    --arg on_demand_broker_vm_extensions "$ON_DEMAND_BROKER_VM_EXTENSIONS" \
    --arg on_demand_broker_plan_1_cf_service_access "$ON_DEMAND_BROKER_PLAN_1_CF_SERVICE_ACCESS" \
    --arg on_demand_broker_plan_1_name "$ON_DEMAND_BROKER_PLAN_1_NAME" \
    --arg on_demand_broker_plan_1_description "$ON_DEMAND_BROKER_PLAN_1_DESCRIPTION" \
    --argjson on_demand_broker_plan_1_instance_quota $ON_DEMAND_BROKER_PLAN_1_INSTANCE_QUOTA \
    --arg on_demand_broker_plan_1_features "$ON_DEMAND_BROKER_PLAN_1_FEATURES" \
    --arg on_demand_broker_plan_1_rabbitmq_az_placement "$ON_DEMAND_BROKER_PLAN_1_RABBITMQ_AZ_PLACEMENT" \
    --arg on_demand_broker_plan_1_rabbitmq_vm_type "$ON_DEMAND_BROKER_PLAN_1_RABBITMQ_VM_TYPE" \
    --arg on_demand_broker_plan_1_rabbitmq_persistent_disk_type "$ON_DEMAND_BROKER_PLAN_1_RABBITMQ_PERSISTENT_DISK_TYPE" \
    --arg on_demand_broker_plan_1_disk_limit_acknowledgement "$ON_DEMAND_BROKER_PLAN_1_DISK_LIMIT_ACKNOWLEDGEMENT" \
    --arg on_demand_broker_plan_2_selector "$ON_DEMAND_BROKER_PLAN_2_SELECTOR" \
    --arg on_demand_broker_plan_2_selector_cf_service_access "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_CF_SERVICE_ACCESS" \
    --arg on_demand_broker_plan_2_selector_name "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_NAME" \
    --arg on_demand_broker_plan_2_selector_description "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_DESCRIPTION" \
    --arg on_demand_broker_plan_2_selector_features "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_FEATURES" \
    --argjson on_demand_broker_plan_2_selector_instance_quota $ON_DEMAND_BROKER_PLAN_2_SELECTOR_INSTANCE_QUOTA \
    --arg on_demand_broker_plan_2_selector_rabbitmq_persistent_disk_type "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_RABBITMQ_PERSISTENT_DISK_TYPE" \
    --argjson on_demand_broker_plan_2_selector_rabbitmq_number_of_nodes $ON_DEMAND_BROKER_PLAN_2_SELECTOR_RABBITMQ_NUMBER_OF_NODES \
    --arg on_demand_broker_plan_2_selector_rabbitmq_cluster_partition_handling_strategy "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_RABBITMQ_CLUSTER_PARTITION_HANDLING_STRATEGY" \
    --arg on_demand_broker_plan_2_selector_rabbitmq_az_placement "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_RABBITMQ_AZ_PLACEMENT" \
    --arg on_demand_broker_plan_2_selector_rabbitmq_vm_type "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_RABBITMQ_VM_TYPE" \
    --arg on_demand_broker_plan_2_selector_disk_limit_acknowledgement "$ON_DEMAND_BROKER_PLAN_2_SELECTOR_DISK_LIMIT_ACKNOWLEDGEMENT" \
    --arg on_demand_broker_plan_3_selector "$ON_DEMAND_BROKER_PLAN_3_SELECTOR" \
    --arg on_demand_broker_plan_3_selector_cf_service_access "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_CF_SERVICE_ACCESS" \
    --arg on_demand_broker_plan_3_selector_name "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_NAME" \
    --arg on_demand_broker_plan_3_selector_description "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_DESCRIPTION" \
    --arg on_demand_broker_plan_3_selector_features "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_FEATURES" \
    --argjson on_demand_broker_plan_3_selector_instance_quota $ON_DEMAND_BROKER_PLAN_3_SELECTOR_INSTANCE_QUOTA \
    --arg on_demand_broker_plan_3_selector_rabbitmq_persistent_disk_type "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_RABBITMQ_PERSISTENT_DISK_TYPE" \
    --argjson on_demand_broker_plan_3_selector_rabbitmq_number_of_nodes $ON_DEMAND_BROKER_PLAN_3_SELECTOR_RABBITMQ_NUMBER_OF_NODES \
    --arg on_demand_broker_plan_3_selector_rabbitmq_cluster_partition_handling_strategy "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_RABBITMQ_CLUSTER_PARTITION_HANDLING_STRATEGY" \
    --arg on_demand_broker_plan_3_selector_rabbitmq_az_placement "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_RABBITMQ_AZ_PLACEMENT" \
    --arg on_demand_broker_plan_3_selector_rabbitmq_vm_type "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_RABBITMQ_VM_TYPE" \
    --arg on_demand_broker_plan_3_selector_disk_limit_acknowledgement "$ON_DEMAND_BROKER_PLAN_3_SELECTOR_DISK_LIMIT_ACKNOWLEDGEMENT" \
    --arg on_demand_broker_plan_4_selector "$ON_DEMAND_BROKER_PLAN_4_SELECTOR" \
    --arg on_demand_broker_plan_4_selector_cf_service_access "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_CF_SERVICE_ACCESS" \
    --arg on_demand_broker_plan_4_selector_name "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_NAME" \
    --arg on_demand_broker_plan_4_selector_description "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_DESCRIPTION" \
    --arg on_demand_broker_plan_4_selector_features "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_FEATURES" \
    --argjson on_demand_broker_plan_4_selector_instance_quota $ON_DEMAND_BROKER_PLAN_4_SELECTOR_INSTANCE_QUOTA \
    --arg on_demand_broker_plan_4_selector_rabbitmq_persistent_disk_type "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_RABBITMQ_PERSISTENT_DISK_TYPE" \
    --argjson on_demand_broker_plan_4_selector_rabbitmq_number_of_nodes $ON_DEMAND_BROKER_PLAN_4_SELECTOR_RABBITMQ_NUMBER_OF_NODES \
    --arg on_demand_broker_plan_4_selector_rabbitmq_cluster_partition_handling_strategy "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_RABBITMQ_CLUSTER_PARTITION_HANDLING_STRATEGY" \
    --arg on_demand_broker_plan_4_selector_rabbitmq_az_placement "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_RABBITMQ_AZ_PLACEMENT" \
    --arg on_demand_broker_plan_4_selector_rabbitmq_vm_type "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_RABBITMQ_VM_TYPE" \
    --arg on_demand_broker_plan_4_selector_disk_limit_acknowledgement "$ON_DEMAND_BROKER_PLAN_4_SELECTOR_DISK_LIMIT_ACKNOWLEDGEMENT" \
    --arg on_demand_broker_plan_5_selector "$ON_DEMAND_BROKER_PLAN_5_SELECTOR" \
    --arg on_demand_broker_plan_5_selector_cf_service_access "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_CF_SERVICE_ACCESS" \
    --arg on_demand_broker_plan_5_selector_name "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_NAME" \
    --arg on_demand_broker_plan_5_selector_description "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_DESCRIPTION" \
    --arg on_demand_broker_plan_5_selector_features "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_FEATURES" \
    --argjson on_demand_broker_plan_5_selector_instance_quota $ON_DEMAND_BROKER_PLAN_5_SELECTOR_INSTANCE_QUOTA \
    --arg on_demand_broker_plan_5_selector_rabbitmq_persistent_disk_type "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_RABBITMQ_PERSISTENT_DISK_TYPE" \
    --argjson on_demand_broker_plan_5_selector_rabbitmq_number_of_nodes $ON_DEMAND_BROKER_PLAN_5_SELECTOR_RABBITMQ_NUMBER_OF_NODES \
    --arg on_demand_broker_plan_5_selector_rabbitmq_cluster_partition_handling_strategy "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_RABBITMQ_CLUSTER_PARTITION_HANDLING_STRATEGY" \
    --arg on_demand_broker_plan_5_selector_rabbitmq_az_placement "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_RABBITMQ_AZ_PLACEMENT" \
    --arg on_demand_broker_plan_5_selector_rabbitmq_vm_type "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_RABBITMQ_VM_TYPE" \
    --arg on_demand_broker_plan_5_selector_disk_limit_acknowledgement "$ON_DEMAND_BROKER_PLAN_5_SELECTOR_DISK_LIMIT_ACKNOWLEDGEMENT" \
    --arg disk_alarm_threshold "$DISK_ALARM_THRESHOLD" \
    --arg server_admin_username "$SERVER_ADMIN_USERNAME" \
    --arg server_admin_password "$SERVER_ADMIN_PASSWORD" \
    --arg rabbitmq_server_plugins "$RABBITMQ_SERVER_PLUGINS" \
    --arg ssl_cert_pem "$SSL_CERT_PEM" \
    --arg ssl_private_key_pem "$SSL_PRIVATE_KEY_PEM" \
    --arg ssl_cacert "$SSL_CACERT" \
    --argjson ssl_verify $SSL_VERIFY \
    --argjson ssl_verification_depth $SSL_VERIFICATION_DEPTH \
    --argjson ssl_fail_if_no_peer_cert $SSL_FAIL_IF_NO_PEER_CERT \
    --arg rabbitmq_server_cookie "$RABBITMQ_SERVER_COOKIE" \
    --arg rabbitmq_server_config "$RABBITMQ_SERVER_CONFIG" \
    --arg ssl_versions "$SSL_VERSIONS" \
    --arg cluster_partition_handling "$CLUSTER_PARTITION_HANDLING" \
    --arg rabbitmq_server_ports "$RABBITMQ_SERVER_PORTS" \
    --arg rabbitmq_server_static_ips "$RABBITMQ_SERVER_STATIC_IPS" \
    --arg rabbitmq_haproxy_static_ips "$RABBITMQ_HAPROXY_STATIC_IPS" \
    --arg rabbitmq_broker_dns_host "$RABBITMQ_BROKER_DNS_HOST" \
    --argjson operator_set_policy_enabled $OPERATOR_SET_POLICY_ENABLED \
    --arg policy_definition "$POLICY_DEFINITION" \
    --argjson global_service_instance_quota $GLOBAL_SERVICE_INSTANCE_QUOTA \
    '
    . +
    {
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
        "value": $syslog_selector_address
      },
      ".properties.syslog_selector.enabled.port": {
        "value": $syslog_selector_port
      },
      ".properties.syslog_selector.enabled.syslog_transport": {
        "value": $syslog_selector_syslog_transport
      },
      ".properties.syslog_selector.enabled.syslog_format": {
        "value": $syslog_selector_syslog_format
      },
      ".properties.syslog_selector.enabled.syslog_tls": {
        "value": $syslog_selector_syslog_tls
      },
      ".properties.syslog_selector.enabled.syslog_permitted_peer": {
        "value": $syslog_selector_syslog_permitted_peer
      },
      ".properties.syslog_selector.enabled.syslog_ca_cert": {
        "value": $syslog_selector_syslog_ca_cert
      }
    }
    else .
    end
    +
    {
      ".properties.on_demand_broker_vm_extensions": {
        "value": $on_demand_broker_vm_extensions
      },
      ".properties.on_demand_broker_plan_1_cf_service_access": {
        "value": $on_demand_broker_plan_1_cf_service_access
      },
      ".properties.on_demand_broker_plan_1_name": {
        "value": $on_demand_broker_plan_1_name
      },
      ".properties.on_demand_broker_plan_1_description": {
        "value": $on_demand_broker_plan_1_description
      },
      ".properties.on_demand_broker_plan_1_instance_quota": {
        "value": $on_demand_broker_plan_1_instance_quota
      },
      ".properties.on_demand_broker_plan_1_features": {
        "value": $on_demand_broker_plan_1_features
      },
      ".properties.on_demand_broker_plan_1_rabbitmq_az_placement": {
        "value": ($on_demand_broker_plan_1_rabbitmq_az_placement | split(",") | map(.))
      },
      ".properties.on_demand_broker_plan_1_rabbitmq_vm_type": {
        "value": $on_demand_broker_plan_1_rabbitmq_vm_type
      },
      ".properties.on_demand_broker_plan_1_rabbitmq_persistent_disk_type": {
        "value": $on_demand_broker_plan_1_rabbitmq_persistent_disk_type
      },
      ".properties.on_demand_broker_plan_1_disk_limit_acknowledgement": {
        "value": ($on_demand_broker_plan_1_disk_limit_acknowledgement | split(",") | map(.))
      },
      ".properties.on_demand_broker_plan_2_selector": {
        "value": $on_demand_broker_plan_2_selector
      }
    }
    +
    if $on_demand_broker_plan_2_selector == "enabled" then
    {
      ".properties.on_demand_broker_plan_2_selector.enabled.cf_service_access": {
        "value": $on_demand_broker_plan_2_selector_cf_service_access
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.name": {
        "value": $on_demand_broker_plan_2_selector_name
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.description": {
        "value": $on_demand_broker_plan_2_selector_description
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.features": {
        "value": $on_demand_broker_plan_2_selector_features
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.instance_quota": {
        "value": $on_demand_broker_plan_2_selector_instance_quota
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.rabbitmq_persistent_disk_type": {
        "value": $on_demand_broker_plan_2_selector_rabbitmq_persistent_disk_type
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.rabbitmq_number_of_nodes": {
        "value": $on_demand_broker_plan_2_selector_rabbitmq_number_of_nodes
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.rabbitmq_cluster_partition_handling_strategy": {
        "value": $on_demand_broker_plan_2_selector_rabbitmq_cluster_partition_handling_strategy
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.rabbitmq_az_placement": {
        "value": ($on_demand_broker_plan_2_selector_rabbitmq_az_placement | split(",") | map(.))
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.rabbitmq_vm_type": {
        "value": $on_demand_broker_plan_2_selector_rabbitmq_vm_type
      },
      ".properties.on_demand_broker_plan_2_selector.enabled.disk_limit_acknowledgement": {
        "value": ($on_demand_broker_plan_2_selector_disk_limit_acknowledgement | split(",") | map(.))
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
          "identity": $server_admin_username,
          "password": $server_admin_password
        }
      },
      ".rabbitmq-server.plugins": {
        "value": ($rabbitmq_server_plugins | split(",") | map(.))
      },
      ".rabbitmq-server.rsa_certificate": {
        "value": {
          "cert_pem": $ssl_cert_pem,
          "private_key_pem": $ssl_private_key_pem
        }
      },
      ".rabbitmq-server.ssl_cacert": {
        "value": $ssl_cacert
      },
      ".rabbitmq-server.ssl_verify": {
        "value": $ssl_verify
      },
      ".rabbitmq-server.ssl_verification_depth": {
        "value": $ssl_verification_depth
      },
      ".rabbitmq-server.ssl_fail_if_no_peer_cert": {
        "value": $ssl_fail_if_no_peer_cert
      },
      ".rabbitmq-server.cookie": {
        "value": $rabbitmq_server_cookie
      },
      ".rabbitmq-server.config": {
        "value": $rabbitmq_server_config
      },
      ".rabbitmq-server.ssl_versions": {
        "value": ($ssl_versions | split(",") | map(.))
      },
      ".rabbitmq-server.cluster_partition_handling": {
        "value": $cluster_partition_handling
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
        "value": $operator_set_policy_enabled
      },
      ".rabbitmq-broker.policy_definition": {
        "value": $policy_definition
      },
      ".on-demand-broker.global_service_instance_quota": {
        "value": $global_service_instance_quota
      }
    }
    '
)

PRODUCT_RESOURCES=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg rmq_server_instance_type $RMQ_SERVER_INSTANCE_TYPE \
    --argjson rmq_server_instances $RMQ_SERVER_INSTANCES \
    --arg rmq_server_node_persistent_disk_size $RMQ_SERVER_NODE_PERSISTENT_DISK_SIZE \
    --arg rmq_haproxy_instance_type $RMQ_HAPROXY_INSTANCE_TYPE \
    --argjson rmq_haproxy_instances $RMQ_HAPROXY_INSTANCES \
    --arg rmq_broker_instance_type $RMQ_BROKER_INSTANCE_TYPE \
    --argjson rmq_broker_instances $RMQ_BROKER_INSTANCES \
    --arg rmq_ondemand_instance_type $RMQ_ONDEMAND_INSTANCE_TYPE \
    --argjson rmq_ondemand_instances $RMQ_ONDEMAND_INSTANCES \
    --arg rmq_ondemand_persistent_disk_size $RMQ_ONDEMAND_PERSISTENT_DISK_SIZE \
    '
    . +
    {
      "rabbitmq-server": {
        "instance_type": {"id": $rmq_server_instance_type},
        "instances": $rmq_server_instances,
        "persistent_disk": {"size_mb": $rmq_server_node_persistent_disk_size}
      },
      "rabbitmq-haproxy": {
        "instance_type": {"id": $rmq_haproxy_instance_type},
        "instances": $rmq_haproxy_instances
      },
      "rabbitmq-broker": {
        "instance_type": {"id": $rmq_broker_instance_type},
        "instances": $rmq_broker_instances
      },
      "on-demand-broker": {
        "instance_type": {"id": $rmq_ondemand_instance_type},
        "instances": $rmq_ondemand_instances,
        "persistent_disk": {"size_mb": $rmq_ondemand_persistent_disk_size}
      }
    }
    '
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$PRODUCT_PROPERTIES" -pr "$PRODUCT_RESOURCES"
