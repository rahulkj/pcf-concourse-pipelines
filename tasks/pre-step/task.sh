#!/bin/bash

echo "this is a sample"

chmod +x om-cli/om-linux

ERT_ERRANDS=$(cat <<-EOF
{"errands": [
  {"name": "smoke-tests","post_deploy": false}
]}
EOF
)

echo "Disabling Smoke Tests"
CF_GUID=`./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/deployed/products" -x GET | jq '.[] | select(.installation_name | contains("cf-")) | .guid' | tr -d '"'`

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/products/$CF_GUID/errands" -x PUT -d "$ERT_ERRANDS"

METRICS_ERRANDS=$(cat <<-EOF
{"errands": [
  {"name": "integration-tests","post_deploy": false}
]}
EOF
)

echo "Disable Metrics Errands"
METRICS_GUID=`./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/deployed/products" -x GET | jq '.[] | select(.type | contains("p-metrics")) | .installation_name' | tr -d '"'`

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/products/$METRICS_GUID/errands" -x PUT -d "$METRICS_ERRANDS"

echo "Use External NON SSL for Networking"
CF_PROPERTIES=$(cat <<-EOF
{
  .properties.networking_point_of_entry: {
    value: "external_non_ssl"
  }
}
EOF
)

/om-cli/om-linux -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_PROPERTIES"
