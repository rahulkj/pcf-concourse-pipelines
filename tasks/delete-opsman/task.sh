#!/bin/bash

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64

export GOVC_INSECURE=1
export GOVC_URL=$VCENTER_HOST
export GOVC_USERNAME=$VCENTER_USR
export GOVC_PASSWORD=$VCENTER_PWD

if curl -s https://$OPS_MGR_HOST >/dev/null
then
  ./govc/govc_linux_amd64 vm.destroy -vm.ip=$OPS_MGR_IP
else
  echo "Ops Manager not reachable or does not exist"
fi
