#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

ERT_ERRANDS=$(cat <<-EOF
{"errands": [
  {"name": "smoke-tests","post_deploy": true},
  {"name": "push-apps-manager","post_deploy": true},
  {"name": "notifications","post_deploy": true},
  {"name": "notifications-ui","post_deploy": true},
  {"name": "push-pivotal-account","post_deploy": true},
  {"name": "autoscaling","post_deploy": true},
  {"name": "autoscaling-register-broker","post_deploy": true}
]}
EOF
)

CF_GUID=`$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/deployed/products" -x GET | jq '.[] | select(.installation_name | contains("cf-")) | .guid' | tr -d '"'`

$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/products/$CF_GUID/errands" -x PUT -d "$ERT_ERRANDS"
