#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

PRODUCT_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --argjson broker_max_instances "$BROKER_MAX_INSTANCES" \
    --arg buildpack "$BUILDPACK" \
    --argjson disable_cert_check "$DISABLE_CERT_CHECK" \
    --argjson instances_app_push_timeout "$INSTANCES_APP_PUSH_TIMEOUT" \
    --argjson enable_global_access "$ENABLE_GLOBAL_ACCESS" \
    --arg persistence_store_service "$PERSISTENCE_STORE_SERVICE" \
    --arg persistence_store_service_plan "$PERSISTENCE_STORE_SERVICE_PLAN" \
    --arg message_bus_service "$MESSAGE_BUS_SERVICE" \
    --arg message_bus_service_plan "$MESSAGE_BUS_SERVICE_PLAN" \
    --argjson secure_credentials "$SECURE_CREDENTIALS" \
    '
    . +
    {
      ".deploy-service-broker.broker_max_instances": {
        "value": $broker_max_instances
      },
      ".deploy-service-broker.buildpack": {
        "value": $buildpack
      },
      ".deploy-service-broker.disable_cert_check": {
        "value": $disable_cert_check
      },
      ".deploy-service-broker.instances_app_push_timeout": {
        "value": $instances_app_push_timeout
      },
      ".deploy-service-broker.persistence_store_service": {
        "value": $persistence_store_service
      },
      ".deploy-service-broker.persistence_store_service_plan": {
        "value": $persistence_store_service_plan
      },
      ".deploy-service-broker.message_bus_service": {
        "value": $message_bus_service
      },
      ".deploy-service-broker.message_bus_service_plan": {
        "value": $message_bus_service_plan
      },
      ".deploy-service-broker.secure_credentials": {
        "value": $secure_credentials
      },
      ".register-service-broker.enable_global_access": {
        "value": $enable_global_access
      }
    }
    '
)

PRODUCT_NETWORK=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg singleton_jobs_az "$SINGLETON_JOBS_AZ" \
    --arg other_azs "$OTHER_AZS" \
    --arg network_name "$NETWORK_NAME" \
    '. +
    {
      "singleton_availability_zone": {
        "name": $singleton_jobs_az
      },
      "other_availability_zones": ($other_azs | split(",") | map({name: .})),
      "network": {
        "name": $network_name
      }
    }
    '
)



$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK" -p "$PRODUCT_PROPERTIES"
