#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux

CMD=./om-cli/om-linux

printf 'waiting for OpsManager endpoint to be available'
until $(curl --output /dev/null -k --silent --head --fail https://$OPS_MGR_HOST/setup); do
    printf '.'
    sleep 5
done

$CMD -t https://$OPS_MGR_HOST -k configure-authentication -u $OPS_MGR_USR -p $OPS_MGR_PWD -dp $OM_DECRYPTION_PWD
