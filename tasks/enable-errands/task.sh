#!/bin/bash -ex

chmod +x om-cli/om-linux
CMD=./om-cli/om-linux

if [[ ! -z "$ERRANDS" ]]; then
  echo "Errands to enable are " $ERRANDS
  for i in $(echo $ERRANDS | sed "s/,/ /g")
  do
    echo "$i"
    set +e
    ERRAND_EXISTS=`$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD errands \
      -p $PRODUCT_IDENTIFIER | grep -w "\s$i\s"`

    set -e
    echo $ERRAND_EXISTS

    if [[ ! -z "$ERRAND_EXISTS" ]]; then
      echo $i " errand found... and enabling..."
      $CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
        set-errand-state -p $PRODUCT_IDENTIFIER -e $i --post-deploy-state enabled
    else
      echo $i " errand not found... skipping..."
    fi
  done
else
  echo "No errands to enable"
fi
