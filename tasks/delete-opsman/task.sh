#!/bin/bash

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64

export GOVC_INSECURE=1
export GOVC_URL=$VCENTER_HOST
export GOVC_USERNAME=$VCENTER_USR
export GOVC_PASSWORD=$VCENTER_PWD

PING_RESPONSE=`ping -c 1 -n $OPS_MGR_IP -i 1 | grep "100.0% packet loss"`

if [[ -z $VM_EXISTS ]]; then
  ./govc/govc_linux_amd64 vm.destroy -vm.ip=$OPS_MGR_IP
else
  echo "$OPS_MGR_IP is down or does not exist"
fi  
