echo "This utility will set all the install pipelines for you"

read -p "Concourse Alias:  " ALIAS
read -p "Concourse FQDN: " CONCOURSE_URL
read -p "Path to the params files: " PARAMS_PATH
read -s -p "Concourse admin password: " CONCOURSE_USERNAME
read -s -p "Concourse admin password: " CONCOURSE_PASSWORD
read -p "Concourse team name: " CONCOURSE_TEAM

declare PIPELINES=("redis" "rabbbitmq" "mysql" "spring-cloud-services" "healthwatch" "pcf-metrics" "mysql-v2" "spring-cloud-dataflow" "splunk-nozzle" "newrelic-nozzle" "newrelic-service-broker" "isolation-segments" )

fly -t ${ALIAS} login -c https://${CONCOURSE_URL} -k -u ${CONCOURSE_USERNAME} -p ${CONCOURSE_PASSWORD} -n ${CONCOURSE_TEAM}

for PIPELINE in ${PIPELINES[@]}; do
  if [ ! -f "$PARAMS_PATH/$PIPELINE/params.yml" ]; then
    echo "No params file found for $PIPELINE. Skipping setting the pipelines"
  else
    fly -t ${ALIAS} set-pipeline -p install-$pipeline -c ./pipelines/tiles/$PIPELINE/pipeline.yml -l $PARAMS_PATH/$PIPELINE/params.yml -n
    fly -t ${ALIAS} unpause-pipeline -p install-$PIPELINE
    fly -t ${ALIAS} expose-pipeline -p install-$PIPELINE
  fi
done

echo "Checkout your concourse, it should now be fully loaded :) --> https://$CONCOURSE_URL"
