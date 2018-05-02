#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64
GOVC_CMD=./govc/govc_linux_amd64

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

FILE_PATH=`find ./pivnet-product/ -name *.ova`

$GOVC_CMD import.spec $FILE_PATH | python -m json.tool > om-import.json

cat > filters <<'EOF'
del(.Deployment) |
.Name = $vmName |
.DiskProvisioning = $diskType |
.NetworkMapping[].Network = $network |
.PowerOn = $powerOn |
(.PropertyMapping[] | select(.Key == "ip0")).Value = $ip0 |
(.PropertyMapping[] | select(.Key == "netmask0")).Value = $netmask0 |
(.PropertyMapping[] | select(.Key == "gateway")).Value = $gateway |
(.PropertyMapping[] | select(.Key == "DNS")).Value = $dns |
(.PropertyMapping[] | select(.Key == "ntp_servers")).Value = $ntpServers |
(.PropertyMapping[] | select(.Key == "admin_password")).Value = $adminPassword |
(.PropertyMapping[] | select(.Key == "custom_hostname")).Value = $customHostname
EOF

$JQ_CMD \
  --arg ip0 "$OPS_MGR_IP" \
  --arg netmask0 "$OM_NETMASK" \
  --arg gateway "$OM_GATEWAY" \
  --arg dns "$OM_DNS_SERVERS" \
  --arg ntpServers "$OM_NTP_SERVERS" \
  --arg adminPassword "$OPS_MGR_SSH_PWD" \
  --arg customHostname "$OPS_MGR_HOST" \
  --arg network "$OM_VM_NETWORK" \
  --arg vmName "$OM_VM_NAME" \
  --arg diskType "$OM_DISK_TYPE" \
  --argjson powerOn "$OM_VM_POWER_STATE" \
  --from-file filters \
  om-import.json > options.json

$GOVC_CMD import.ova -options=out.json $FILE_PATH

rm *.json
