#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

echo "$IAAS_CONFIGURATION" > iaas_configuration.yml
echo "$DIRECTOR_CONFIGURATION" > director_configuration.yml
echo "$AZ_CONFIGURATION" > az_configuration.yml
echo "$NETWORK_CONFIGURATION" > network_configuration.yml
echo "$NETWORK_ASSIGNMENT" > network_assignment.yml
echo "$SECURITY_CONFIGURATION" > security_configuration.yml
echo "$RESOURCE_CONFIGURATION" > resource_configuration.yml

iaas_configuration=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < iaas_configuration.yml)
director_configuration=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < director_configuration.yml)
az_configuration=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < az_configuration.yml)
network_configuration=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < network_configuration.yml)
network_assignment=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < network_assignment.yml)
security_configuration=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < security_configuration.yml)
resource_configuration=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < resource_configuration.yml)

echo "Configuring IaaS and Director..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD configure-director \
  -i "$iaas_configuration" \
  -d "$director_configuration"

echo "Configuring availability zones..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  curl -s -p "/api/v0/staged/director/availability_zones" \
  -x PUT -d "$az_configuration"

echo "Configuring network..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  curl -s -p "/api/v0/staged/director/networks" \
  -x PUT -d "$network_configuration"

$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
 curl -s -p /api/v0/staged/director/network_and_az \
 -x PUT -d "$network_assignment"

echo "Configuring network assignment, security..."
$OM_CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  configure-director \
  --security-configuration "$security_configuration" \
  --resource-configuration "$resource_configuration"
