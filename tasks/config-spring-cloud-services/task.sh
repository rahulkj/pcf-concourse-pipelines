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
  }
}
EOF
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG" -p "$PRODUCT_PROPERTIES"
