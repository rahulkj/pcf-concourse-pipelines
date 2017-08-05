#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

if [[ -z "$SSL_CERT" || "$SSL_CERT" == "null" ]]; then
DOMAINS=$(cat <<-EOF
  {"domains": ["*.$JMX_DOMAIN"] }
EOF
)

  CERTIFICATES=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS"`

  export SSL_CERT=`echo $CERTIFICATES | jq '.certificate' | tr -d '"'`
  export SSL_PRIVATE_KEY=`echo $CERTIFICATES | jq '.key' | tr -d '"'`

  echo "Using self signed certificates generated using Ops Manager..."

fi

function fn_balanced_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCED_JOBS_AZS=$(fn_balanced_azs $OTHER_AZS)

NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_AZ"
  },
  "other_availability_zones": [
    $BALANCED_JOBS_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

PROPERTIES=$(cat <<-EOF
{
  ".maximus.credentials": {
    "value": {
      "identity": "$JMX_ADMIN_USR",
      "password": "$JMX_ADMIN_PWD"
    }
  },
  ".maximus.security_logging": {
    "value": "$SECURITY_LOGGING_ENABLED"
  }
}
EOF
)

RESOURCES=$(cat <<-EOF
{
  "maximus": {
    "instance_type": {"id": "$MAXIMUS_INSTANCE_TYPE"},
    "instances" : $MAXIMUS_INSTANCES,
    "persistent_disk_mb": "$MAXIMUS_PERSISTENT_DISK_SIZE_MB"
  },
  "jmx-firehose-nozzle": {
    "instance_type": {"id": "$JMX_FIREHOSE_NOZZLE_INSTANCE_TYPE"},
    "instances" : $JMX_FIREHOSE_NOZZLE_INSTANCES,
    "persistent_disk_mb": "$JMX_FIREHOSE_NOZZLE_PERSISTENT_DISK_SIZE_MB"
  },
  "integration-tests": {
    "instance_type": {"id": "$INTEGRATION_TESTS_INSTANCE_TYPE"},
    "instances" : $INTEGRATION_TESTS_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$PROPERTIES" -pn "$NETWORK" -pr "$RESOURCES"

if [[ "$NAT_ENABLED" == "option_disabled" ]]; then
NAT_SETTINGS=$(cat <<-EOF
{
  ".properties.enable_nat_support": {
    "value": "$NAT_ENABLED"
  }
}
EOF
)
elif [[ "$NAT_ENABLED" == "option_enabled" ]]; then
NAT_SETTINGS=$(cat <<-EOF
{
  ".properties.enable_nat_support": {
    "value": "$NAT_ENABLED"
  },
  ".properties.enable_nat_support.nat_option_enabled.external_ip_address": {
    "value": "$NAT_JMX_BRIDGE_IP"
  }
}
EOF
)
fi

echo "Configuring JMX NATing..."
$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$NAT_SETTINGS"

if [[ "$JMX_USE_SSL" == "true" ]]; then
SSL_CONFIGURATION=$(cat <<-EOF
{
  ".maximus.use_ssl": {
    "value": "$JMX_USE_SSL"
  },
  ".maximus.ssl_rsa_certificate": {
    "value": {
      "cert_pem": "$SSL_CERT",
      "private_key_pem": "$SSL_PRIVATE_KEY"
    }
  },
  ".jmx-firehose-nozzle.use_metric_prefix": {
    "value": "$USE_METRIC_PREFIX"
  }
}
EOF
)
elif [[ "$JMX_USE_SSL" == "false" ]]; then
SSL_CONFIGURATION=$(cat <<-EOF
{
  ".maximus.use_ssl": {
    "value": "$JMX_USE_SSL"
  }
}
EOF
)
fi

echo "Configuring JMX SSL..."
$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$SSL_CONFIGURATION"
