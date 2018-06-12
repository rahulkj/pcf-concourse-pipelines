set -ex

read -p "Folder to copy all the param file to:  " PARAMS_PATH

SCRIPTS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
PARAMS_PATH=$(greadlink -f $PARAMS_PATH)

declare PIPELINES=("redis" "rabbitmq" "mysql" "spring-cloud-services" "healthwatch" "pcf-metrics" "mysql-v2" "spring-cloud-dataflow" "splunk-nozzle" "newrelic-nozzle" "newrelic-service-broker" "isolation-segment" )

if [ ! -z "$PARAMS_PATH" ]; then
  mkdir -p $PARAMS_PATH
fi

for pipeline in ${PIPELINES[@]}; do
  mkdir -p $PARAMS_PATH/$pipeline
  cp $SCRIPTS_DIR/pipelines/tiles/$pipeline/params-template.yml $PARAMS_PATH/$pipeline/creds.yml
done

echo "Done"
