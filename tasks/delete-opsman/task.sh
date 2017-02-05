#!/bin/bash

export GOVC_INSECURE=1
export GOVC_URL=$VCENTER_HOST
export GOVC_USERNAME=$VCENTER_USR
export GOVC_PASSWORD=$VCENTER_PWD

govc vm.destroy -vm.ip=$OPS_MAN_IP
