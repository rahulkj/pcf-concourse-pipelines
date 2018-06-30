#!/bin/bash -e

if [ -z "$__BASEDIR__" ]; then
  FILE_PATH=$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)/$(basename -- "$0")")
  __DIR__="$( cd "$( dirname "${FILE_PATH}" )" && pwd )"
  __BASEDIR__=$(dirname $__DIR__)
fi

if [ -f "$__BASEDIR__/.env.local" ]; then
  source $__BASEDIR__/.env.local
else
  read -p "Concourse Alias:  " ALIAS
  read -p "Concourse FQDN: " CONCOURSE_URL
  read -p "Path to the params files: " PARAMS_PATH
  read -p "Concourse team name: " CONCOURSE_TEAM
  read -p "Concourse admin username: " CONCOURSE_USERNAME

  echo "ALIAS=$ALIAS" >> $__BASEDIR__/.env.local
  echo "CONCOURSE_URL=$CONCOURSE_URL" >> $__BASEDIR__/.env.local
  echo "PARAMS_PATH=$PARAMS_PATH" >> $__BASEDIR__/.env.local
  echo "CONCOURSE_TEAM=$CONCOURSE_TEAM" >> $__BASEDIR__/.env.local
  echo "CONCOURSE_USERNAME=$CONCOURSE_USERNAME" >> $__BASEDIR__/.env.local
fi

read -s -p "Concourse admin password: " CONCOURSE_PASSWORD

echo "This utility will set all the install pipelines for you"

declare PIPELINES=("redis" "rabbbitmq" "mysql" "spring-cloud-services" "healthwatch" "pcf-metrics" "mysql-v2" "spring-cloud-dataflow" "splunk-nozzle" "newrelic-nozzle" "newrelic-service-broker" "isolation-segments" "single-signon")

fly -t ${ALIAS} login -c https://${CONCOURSE_URL} -k -u ${CONCOURSE_USERNAME} -p ${CONCOURSE_PASSWORD} -n ${CONCOURSE_TEAM}

for PIPELINE in ${PIPELINES[@]}; do
  if [ ! -f "$PARAMS_PATH/$PIPELINE/creds.yml" ]; then
    echo "No params file found for $PIPELINE. Skipping setting the pipelines"
  else
    fly -t ${ALIAS} set-pipeline -p install-$PIPELINE -c $__BASEDIR__/pipelines/tiles/$PIPELINE/pipeline.yml -l $PARAMS_PATH/$PIPELINE/creds.yml -n
    fly -t ${ALIAS} unpause-pipeline -p install-$PIPELINE
    fly -t ${ALIAS} expose-pipeline -p install-$PIPELINE
  fi
done

echo "Checkout your concourse, it should now be fully loaded :) --> https://$CONCOURSE_URL"
