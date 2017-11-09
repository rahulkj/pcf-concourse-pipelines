#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

if [[ -z "$SSL_CERT" || "$SSL_CERT" == "null" ]]; then
DOMAINS=$(cat <<-EOF
  {"domains": ["*.$JMX_DOMAIN"] }
EOF
)

  CERTIFICATES=$($OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS")

  export SSL_CERT=$(echo $CERTIFICATES | jq -r '.certificate')
  export SSL_PRIVATE_KEY=$(echo $CERTIFICATES | jq -r '.key')

  echo "Using self signed certificates generated using Ops Manager..."
fi

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

PRODUCT_RESOURCES=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg maximus_instance_type $MAXIMUS_INSTANCE_TYPE \
    --arg maximus_persistent_disk_size_mb $MAXIMUS_PERSISTENT_DISK_SIZE_MB \
    --arg jmx_firehose_nozzle_instance_type $JMX_FIREHOSE_NOZZLE_INSTANCE_TYPE \
    --argjson jmx_firehose_nozzle_instances $JMX_FIREHOSE_NOZZLE_INSTANCES \
    --arg jmx_firehose_nozzle_persistent_disk_size_mb $JMX_FIREHOSE_NOZZLE_PERSISTENT_DISK_SIZE_MB \
    --arg integration_tests_instance_type $INTEGRATION_TESTS_INSTANCE_TYPE \
    '
    . +
    {
      "maximus": {
        "instance_type": {"id": $maximus_instance_type},
        "persistent_disk_mb": $maximus_persistent_disk_size_mb
      },
      "jmx-firehose-nozzle": {
        "instance_type": {"id": $jmx_firehose_nozzle_instance_type},
        "instances" : $jmx_firehose_nozzle_instances,
        "persistent_disk_mb": $jmx_firehose_nozzle_persistent_disk_size_mb
      },
      "integration-tests": {
        "instance_type": {"id": $integration_tests_instance_type}
      }
    }
    '
)

PRODUCT_PROPERTIES=$(
  echo "{}" | $JQ_CMD -n \
    --arg nat_enabled $NAT_ENABLED \
    --arg nat_jmx_bridge_ip $NAT_JMX_BRIDGE_IP \
    --arg jmx_admin_usr $JMX_ADMIN_USR \
    --arg jmx_admin_pwd $JMX_ADMIN_PWD \
    --arg security_logging_enabled $SECURITY_LOGGING_ENABLED \
    --arg jmx_use_ssl $JMX_USE_SSL \
    --arg ssl_cert "$SSL_CERT" \
    --arg ssl_private_key "$SSL_PRIVATE_KEY" \
    --arg use_metric_prefix $USE_METRIC_PREFIX \
    '
    . +
    {
      ".properties.enable_nat_support": {
        "value": $nat_enabled
    }
    +
    if $nat_enabled == "option_enabled" then
    {
      ".properties.enable_nat_support.nat_option_enabled.external_ip_address": {
        "value": $nat_jmx_bridge_ip
      }
    }
    else .
    end
    +
    {
      ".maximus.credentials": {
        "value": {
          "identity": $jmx_admin_usr,
          "password": $jmx_admin_pwd
        }
      },
      ".maximus.security_logging": {
        "value": $security_logging_enabled
      },
      ".maximus.use_ssl": {
        "value": $jmx_use_ssl
      }
    }
    +
    if $jmx_use_ssl == "true" then
    {
      ".maximus.ssl_rsa_certificate": {
        "value": {
          "cert_pem": $ssl_cert,
          "private_key_pem": $ssl_private_key
        }
      }
    }
    else .
    end
    +
    {
      ".jmx-firehose-nozzle.use_metric_prefix": {
        "value": $use_metric_prefix
      }
    }
    '
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_IDENTIFIER -p "$PRODUCT_PROPERTIES" -pn "$PRODUCT_NETWORK" -pr "$PRODUCT_RESOURCES"
