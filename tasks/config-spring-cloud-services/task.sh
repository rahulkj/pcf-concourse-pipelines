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
  --arg deploy_service_broker_broker_max_instances ${DEPLOY_SERVICE_BROKER_BROKER_MAX_INSTANCES:-100} \
  --arg deploy_service_broker_buildpack ${DEPLOY_SERVICE_BROKER_BUILDPACK:-''} \
  --arg deploy_service_broker_disable_cert_check ${DEPLOY_SERVICE_BROKER_DISABLE_CERT_CHECK:-false} \
  --arg deploy_service_broker_instances_app_push_timeout ${DEPLOY_SERVICE_BROKER_INSTANCES_APP_PUSH_TIMEOUT:-''} \
  --arg deploy_service_broker_message_bus_service ${DEPLOY_SERVICE_BROKER_MESSAGE_BUS_SERVICE:-"p-rabbitmq"} \
  --arg deploy_service_broker_message_bus_service_plan ${DEPLOY_SERVICE_BROKER_MESSAGE_BUS_SERVICE_PLAN:-"standard"} \
  --arg deploy_service_broker_persistence_store_service ${DEPLOY_SERVICE_BROKER_PERSISTENCE_STORE_SERVICE:-"p-mysql"} \
  --arg deploy_service_broker_persistence_store_service_plan ${DEPLOY_SERVICE_BROKER_PERSISTENCE_STORE_SERVICE_PLAN:-"100mb"} \
  --arg deploy_service_broker_secure_credentials ${DEPLOY_SERVICE_BROKER_SECURE_CREDENTIALS:-false} \
  --arg register_service_broker_enable_global_access ${REGISTER_SERVICE_BROKER_ENABLE_GLOBAL_ACCESS:-true} \
'{
  ".deploy-service-broker.persistence_store_service": {
    "value": $deploy_service_broker_persistence_store_service
  },
  ".deploy-service-broker.persistence_store_service_plan": {
    "value": $deploy_service_broker_persistence_store_service_plan
  },
  ".deploy-service-broker.message_bus_service": {
    "value": $deploy_service_broker_message_bus_service
  },
  ".deploy-service-broker.message_bus_service_plan": {
    "value": $deploy_service_broker_message_bus_service_plan
  },
  ".deploy-service-broker.broker_max_instances": {
    "value": $deploy_service_broker_broker_max_instances
  },
  ".deploy-service-broker.buildpack": {
    "value": $deploy_service_broker_buildpack
  },
  ".deploy-service-broker.disable_cert_check": {
    "value": $deploy_service_broker_disable_cert_check
  },
  ".deploy-service-broker.instances_app_push_timeout": {
    "value": $deploy_service_broker_instances_app_push_timeout
  },
  ".deploy-service-broker.secure_credentials": {
    "value": $deploy_service_broker_secure_credentials
  },
  ".register-service-broker.enable_global_access": {
    "value": $register_service_broker_enable_global_access
  }
}'
)

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
  --product-name p-spring-cloud-services \
  --product-properties "$properties_config" \
  --product-network "$network_config"
