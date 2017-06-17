#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

METRICS_ERRANDS=$(cat <<-EOF
{"errands": [
  {"name": "integration-tests","post_deploy": false}
]}
EOF
)

METRICS_GUID=`$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/deployed/products" -x GET | jq '.[] | select(.type | contains("p-metrics")) | .installation_name' | tr -d '"'`

$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/products/$METRICS_GUID/errands" -x PUT -d "$METRICS_ERRANDS"
