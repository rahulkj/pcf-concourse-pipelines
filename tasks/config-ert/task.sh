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

CF_RELEASE=$($OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k -f json available-products)

PRODUCT_NAME=$(echo "$CF_RELEASE" | $JQ_CMD -r --arg deployment_name cf '.[] | select(.name==$deployment_name) | .name')
PRODUCT_VERSION=$(echo "$CF_RELEASE" | $JQ_CMD -r --arg deployment_name cf '.[] | select(.name==$deployment_name) | .version')

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

echo "$PRODUCT_PROPERTIES" > properties.yml
echo "$PRODUCT_RESOURCES" > resources.yml
echo "$PRODUCT_NETWORK_AZS" > network-azs.yml

properties_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < properties.yml)
resources_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < resources.yml)
network_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < network-azs.yml)

if [[ "$GENERATE_CERTS" == "true" ]]; then

CLOUD_CONTROLLER_APPS_DOMAIN=$(echo "$properties_config" | jq -r '.".cloud_controller.apps_domain" | .value')
CLOUD_CONTROLLER_SYSTEM_DOMAIN=$(echo "$properties_config" | jq -r '.".cloud_controller.system_domain" | .value')

DOMAINS=$(cat <<-EOF
  {"domains": ["*.$CLOUD_CONTROLLER_SYSTEM_DOMAIN", "*.$CLOUD_CONTROLLER_APPS_DOMAIN", "*.login.$CLOUD_CONTROLLER_SYSTEM_DOMAIN", "*.uaa.$CLOUD_CONTROLLER_SYSTEM_DOMAIN"] }
EOF
)

SECURITY_DOMAIN=$(cat <<-EOF
  {"domains": ["*.login.$CLOUD_CONTROLLER_SYSTEM_DOMAIN", "*.uaa.$CLOUD_CONTROLLER_SYSTEM_DOMAIN"] }
EOF
)

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -s -p "/api/v0/certificates/generate" -x POST -d "$DOMAINS"`

  export NETWORKING_POE_SSL_NAME="GENERATED-CERTS"
  export NETWORKING_POE_SSL_CERT_PEM=`echo $CERTIFICATES | jq --raw-output '.certificate'`
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=`echo $CERTIFICATES | jq --raw-output '.key'`

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -s -p "/api/v0/certificates/generate" -x POST -d "$SECURITY_DOMAIN"`

  export UAA_CERT_PEM=`echo $CERTIFICATES | jq --raw-output '.certificate'`
  export UAA_PRIVATE_KEY_PEM=`echo $CERTIFICATES | jq --raw-output '.key'`


  echo "Using self signed certificates generated using Ops Manager..."

  properties_config=$(echo "$properties_config" | $JQ_CMD \
    --arg networking_poe_ssl_name "$NETWORKING_POE_SSL_NAME" \
    --arg networking_poe_ssl_cert_pem "$NETWORKING_POE_SSL_CERT_PEM" \
    --arg networking_poe_ssl_cert_private_key_pem "$NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM" \
    --arg uaa_cert_pem "$UAA_CERT_PEM" \
    --arg uaa_private_key_pem "$UAA_PRIVATE_KEY_PEM" \
    '
    . +
    {
      ".properties.networking_poe_ssl_certs": {
        "value": [
          {
            "name": $networking_poe_ssl_name,
            "certificate": {
              "cert_pem":$networking_poe_ssl_cert_pem,
              "private_key_pem":$networking_poe_ssl_cert_private_key_pem
            }
          }
        ]
      },
      ".uaa.service_provider_key_credentials": {
        "value": {
          "private_key_pem": $uaa_private_key_pem,
          "cert_pem": $uaa_cert_pem
        }
      }
    }
    '
  )
fi

#$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < properties.yml)

#ruby -ryaml -rjson -e 'puts YAML.dump(JSON.parse(STDIN.read))' < cf.json

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-network "$network_config"

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-properties "$properties_config"

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-resources "$resources_config"
