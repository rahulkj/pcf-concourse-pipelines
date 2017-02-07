#!/bin/bash

ERRANDS=$(cat <<-EOF
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

uaac target https://$OPS_MGR_HOST/uaa --skip-ssl-validation
uaac token owner get opsman $OPS_MGR_USR -s "" -p $OPS_MGR_PWD
UAA_ACCESS_TOKEN=`cat ~/.uaac.yml | grep "access_token" | cut -d ":" -f2 | tr -d " "`

curl -k "https://$OPS_MGR_HOST/api/v0/staged/products/cf-7e4e34dcc3d9988f0a80/errands" -X PUT -H "Authorization: Bearer $UAA_ACCESS_TOKEN" -H "Content-Type: application/json" -d "$ERRANDS"
