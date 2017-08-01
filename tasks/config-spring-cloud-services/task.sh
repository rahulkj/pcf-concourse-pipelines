#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PROPERTIES_CONFIG=$(cat <<-EOF
{
  ".deploy-service-broker.broker_max_instances": {
    "value": "$BROKER_MAX_INSTANCES"
  },
  ".deploy-service-broker.buildpack": {
    "value": "$BUILDPACK"
  },
  ".deploy-service-broker.disable_cert_check": {
    "value": "$DISABLE_CERT_CHECK"
  },
  ".deploy-service-broker.instances_app_push_timeout": {
    "value": "$APP_PUSH_TIMEOUT"
  },
  ".register-service-broker.enable_global_access": {
    "value": "$ENABLE_GLOBAL_ACCESS"
  }
}
EOF
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
  },
  "service_network": {
    "name": "$SERVICES_NETWORK"
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -pn "$PRODUCT_NETWORK_CONFIG"
