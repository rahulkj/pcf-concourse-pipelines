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

NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$AZ_NAME"
  },
  "other_availability_zones": [
    { "name": "$AZ_NAME" }
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
  ".properties.enable_nat_support": {
    "value": "$NAT_ENABLED"
  },
  ".properties.enable_nat_support.nat_option_enabled.external_ip_address": {
    "value": "$NAT_JMX_BRIDGE_IP"
  },
  ".maximus.security_logging": {
    "value": "$SECURITY_LOGGING_ENABLED"
  },
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

RESOURCES=$(cat <<-EOF
{
  "maximus": {
    "instance_type": {"id": "$MAXIMUS_INSTANCE_TYPE"},
    "instances" : $MAXIMUS_INSTANCES
  },
  "jmx-firehose-nozzle": {
    "instance_type": {"id": "$JMX_FIREHOSE_NOZZLE_INSTANCE_TYPE"},
    "instances" : $JMX_FIREHOSE_NOZZLE_INSTANCES
  },
  "integration-tests": {
    "instance_type": {"id": "$INTEGRATION_TESTS_INSTANCE_TYPE"},
    "instances" : $INTEGRATION_TESTS_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$PROPERTIES" -pn "$NETWORK" -pr "$RESOURCES"
