#!/bin/bash
chmod +x om-cli/om-linux

CMD=./om-cli/om-linux

$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/installations" -x POST -d '{ "ignore_warnings": "true" }'

$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD apply-changes
