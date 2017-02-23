#!/bin/bash
chmod +x om-cli/om-linux

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/installations" -x POST -d '{ "ignore_warnings": "true" }'
