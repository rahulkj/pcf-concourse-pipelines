#!/bin/bash

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64

export GOVC_INSECURE=1
export GOVC_URL=$VCENTER_HOST
export GOVC_USERNAME=$VCENTER_USR
export GOVC_PASSWORD=$VCENTER_PWD

set +e

./govc/govc_linux_amd64 vm.destroy -vm.ip=$OPS_MGR_IP
