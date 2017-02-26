#!/bin/bash

chmod +x om-cli/om-linux

if curl -s -k -o /dev/null --fail http://$OPS_MGR_HOST; then
  ./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD delete-installation
else
  echo "Ops Manager not reachable or does not exist"
fi
