#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PRODUCT_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --argjson broker_max_instances "$BROKER_MAX_INSTANCES" \
    --arg buildpack "$BUILDPACK" \
    --argjson disable_cert_check "$DISABLE_CERT_CHECK" \
    --argjson instances_app_push_timeout "$INSTANCES_APP_PUSH_TIMEOUT" \
    --argjson enable_global_access "$ENABLE_GLOBAL_ACCESS" \
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
