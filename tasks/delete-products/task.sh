#!/bin/bash

chmod + om-cli/om-linux

./om-cli/om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD delete-installation
