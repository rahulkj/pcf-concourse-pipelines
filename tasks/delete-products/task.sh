#!/bin/bash

chmod +x om-cli/om-linux

CURL_RESPONSE=`curl -I -s -L https://$OPS_MGR_HOST | grep "HTTP/1.1" | grep "200 OK"`

if [[ ! -z $CURL_RESPONSE ]]; then
  ./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD delete-installation
else
  echo "Ops Manager not reachable or does not exist"
fi
