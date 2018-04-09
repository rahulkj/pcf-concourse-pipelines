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

PRODUCT_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg opsmanager_url "$OPS_MGR_HOST" \
    --argjson mysql_skip_name_resolve "$MYSQL_SKIP_NAME_RESOLVE" \
    --arg foundation_name "$HEALTHWATCH_FOUNDATION_NAME" \
    --argjson ingestor_instances "$HEALTHWATCH_FORWARDER_INGESTOR_INSTANCES" \
    --argjson loader_instances "$HEALTHWATCH_FORWARDER_LOADER_INSTANCES" \
    --argjson canary_instances "$HEALTHWATCH_FORWARDER_CANARY_INSTANCES" \
    --argjson bosh_health_instances "$HEALTHWATCH_FORWARDER_BOSH_HEALTH_INSTANCES" \
    --argjson bosh_tasks_instances "$HEALTHWATCH_FORWARDER_BOSH_TASKS_INSTANCES" \
    --argjson cli_instances "$HEALTHWATCH_FORWARDER_CLI_INSTANCES" \
    --argjson opsman_instances "$HEALTHWATCH_FORWARDER_OPSMAN_INSTANCES" \
    --arg health_check_az "$HEALTHWATCH_FORWARDER_HEALTHCHECK_AZ" \
    '
    . +
    {
      ".mysql.skip_name_resolve": {
        "value": $mysql_skip_name_resolve
      },
       ".healthwatch-forwarder.ingestor_instance_count": {
        "value": $ingestor_instances
      },
      ".healthwatch-forwarder.loader_instance_count": {
        "value": $loader_instances
      },
      ".healthwatch-forwarder.canary_instance_count": {
        "value": $canary_instances
      },
      ".healthwatch-forwarder.boshhealth_instance_count": {
        "value": $bosh_health_instances
      },
      ".healthwatch-forwarder.boshtasks_instance_count": {
        "value": $bosh_tasks_instances
      },
      ".healthwatch-forwarder.cli_instance_count": {
        "value": $cli_instances
      },
      ".healthwatch-forwarder.opsman_instance_count": {
        "value": $opsman_instances
      },
      ".healthwatch-forwarder.health_check_az": {
        "value": $health_check_az
      },
      ".healthwatch-forwarder.opsmanager_url": {
        "value": $opsmanager_url
      }
    } +
    if $foundation_name != "" then
    {
      ".healthwatch-forwarder.foundation_name": {
        "value": $foundation_name
      }
    }
    else .
    end
    '
)

PRODUCT_NETWORK=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg singleton_jobs_az "$SINGLETON_JOBS_AZ" \
    --arg other_azs "$OTHER_AZS" \
    --arg network_name "$NETWORK_NAME" \
    --arg service_network_name "$SERVICE_NETWORK_NAME" \
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

# network must be configured first, so make two separate om calls
$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK"
$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER  -p "$PRODUCT_PROPERTIES"
