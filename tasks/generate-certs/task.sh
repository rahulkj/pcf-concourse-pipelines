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

echo "$DOMAINS" > domains.yml
domains=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < domains.yml)

CERTIFICATES=$($OM_CMD --env env/"${ENV_FILE}" -k curl -s -p "/api/v0/certificates/generate" -x POST -d "$domains")

echo "$CERTIFICATES"

CERT_PEM=`echo $CERTIFICATES | $JQ_CMD --raw-output '.certificate'`
PRIVATE_KEY_PEM=`echo $CERTIFICATES | $JQ_CMD --raw-output '.key'`

echo "Public certificate PEM is:"
echo ""
echo "$CERT_PEM"

echo "Private Key PEM is"
echo ""
echo "$PRIVATE_KEY_PEM"
