#!/bin/bash

chmod +x om-cli/om-linux

ERT_ERRANDS=$(cat <<-EOF
{"errands": [
  {"name": "smoke-tests","post_deploy": false},
  {"name": "push-apps-manager","post_deploy": false},
  {"name": "notifications","post_deploy": false},
  {"name": "notifications-ui","post_deploy": false},
  {"name": "push-pivotal-account","post_deploy": false},
  {"name": "autoscaling","post_deploy": false},
  {"name": "autoscaling-register-broker","post_deploy": false}
]}
EOF
)

METRICS_ERRANDS=$(cat <<-EOF
{"errands": [
  {"name": "smoke-tests","post_deploy": false}
]}
EOF
)

CF_GUID=`./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/deployed/products" -x GET | jq '.[] | select(.installation_name | contains("cf-")) | .guid' | tr -d '"'`

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/products/$CF_GUID/errands" -x PUT -d "$ERT_ERRANDS"

METRICS_GUID=`./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/deployed/products" -x GET | jq '.[] | select(.type | contains("p-metrics")) | .installation_name' | tr -d '"'`

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/products/$METRICS_GUID/errands" -x PUT -d "$METRICS_ERRANDS"
