#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64

CMD=./govc/govc_linux_amd64

$CMD vm.destroy -vm.ip=$OPS_MGR_IP
