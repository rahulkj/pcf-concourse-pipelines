#!/bin/bash
set -e

cp /om-alpine /usr/local/bin

CWD=$(pwd)

# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="concourse-vsphere/tasks/configure-rabbitmq"
json_file_template="${json_file_path}/${RABBITMQ_TEMPLATE}"
json_file="${json_file_path}/rabbitmq.json"

cp ${json_file_template} ${json_file}

for i in $(seq 1 $AZ_COUNT); do
  azString="AZ"$i
  sed -i -e "s/{{$azString}}/${!azString}/g" ${json_file}
done

sed -i -e "s|{{RABBITMQ_NETWORK}}|${RABBITMQ_NETWORK}|g" ${json_file}
sed -i -e "s|{{RABBITMQ_SINGLETON_AZ}}|${RABBITMQ_SINGLETON_AZ}|g" ${json_file}
sed -i -e "s|{{RABBITMQ_ADMIN_USERNAME}}|${RABBITMQ_ADMIN_USERNAME}|g" ${json_file}
sed -i -e "s|{{RABBITMQ_ADMIN_PASSWORD}}|${RABBITMQ_ADMIN_PASSWORD}|g" ${json_file}

function fn_om_linux_curl {

    local curl_method=${1}
    local curl_path=${2}
    local curl_data=${3}

     curl_cmd="om-alpine --target https://$OPSMAN_HOST -k --username \"$OPSMAN_USER\" --password \"$OPSMAN_PASSWORD\"  \
            curl --request ${curl_method} --path ${curl_path}"

    if [[ ! -z ${curl_data} ]]; then
       curl_cmd="${curl_cmd} --data '${curl_data}'"
    fi

    echo ${curl_cmd} > /tmp/rqst_cmd.log
    exec_out=$(((eval $curl_cmd | tee /tmp/rqst_stdout.log) 3>&1 1>&2 2>&3 | tee /tmp/rqst_stderr.log) &>/dev/null)

    if [[ $(cat /tmp/rqst_stderr.log | grep "Status:" | awk '{print$2}') != "200" ]]; then
      echo "Error Call Failed ...."
      echo $(cat /tmp/rqst_stderr.log)
      exit 1
    else
      echo $(cat /tmp/rqst_stdout.log)
    fi
}



echo "=============================================================================================="
echo "Deploying RabbitMQ @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="
# Get cf Product Guid
guid_rabbitmq=$(fn_om_linux_curl "GET" "/api/v0/staged/products" | jq '.[] | select(.type == "p-rabbitmq") | .guid' | tr -d '"' | grep "p-rabbitmq-.*")

echo "=============================================================================================="
echo "Found RabbitMQ Deployment with guid of ${guid_rabbitmq}"
echo "=============================================================================================="

# Set Networks & AZs
echo "=============================================================================================="
echo "Setting Availability Zones & Networks for: ${guid_rabbitmq}"
echo "=============================================================================================="


json_net_and_az=$(cat ${json_file} | jq .networks_and_azs)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_rabbitmq}/networks_and_azs" "${json_net_and_az}"

# Set RabbitMQ Properties
echo "=============================================================================================="
echo "Setting Properties for: ${guid_rabbitmq}"
echo "=============================================================================================="

json_properties=$(cat ${json_file} | jq .properties)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_rabbitmq}/properties" "${json_properties}"

# Set Resource Configs
echo "=============================================================================================="
echo "Setting Resource Job Properties for: ${guid_rabbitmq}"
echo "=============================================================================================="
json_jobs_configs=$(cat ${json_file} | jq .jobs )
json_job_guids=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${guid_rabbitmq}/jobs" | jq .)

for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do
  json_job_guid_cmd="echo \${json_job_guids} | jq '.jobs[] | select(.name == \"${job}\") | .guid' | tr -d '\"'"
  json_job_guid=$(eval ${json_job_guid_cmd})
  json_job_config_cmd="echo \${json_jobs_configs} | jq '.[\"${job}\"]' "
  json_job_config=$(eval ${json_job_config_cmd})
  echo "Configuring $job ---------------------------------------------------------------------------------------------"
  echo "Setting ${json_job_guid} with --data=${json_job_config}..."
  fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_rabbitmq}/jobs/${json_job_guid}/resource_config" "${json_job_config}"
done
