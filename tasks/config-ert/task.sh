#!/bin/bash -ex

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

CF_RELEASE=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep cf`

PRODUCT_NAME=`echo $CF_RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $CF_RELEASE | cut -d"|" -f3 | tr -d " "`

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

function fn_ert_balanced_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

ERT_AZS=$(fn_ert_balanced_azs $DEPLOYMENT_NW_AZS)

CF_NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOBS_AZ"
  },
  "other_availability_zones": [
    $OTHER_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

if [[ -z "$NETWORKING_POE_SSL_CERT_PEM" ]]; then
DOMAINS=$(cat <<-EOF
  {"domains": ["*.$SYSTEM_DOMAIN", "*.$APPS_DOMAIN", "*.login.$SYSTEM_DOMAIN", "*.uaa.$SYSTEM_DOMAIN"] }
EOF
)

SECURITY_DOMAIN=$(cat <<-EOF
  {"domains": ["*.login.$SYSTEM_DOMAIN"] }
EOF
)

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS"`

  export NETWORKING_POE_SSL_NAME="GENERATED-CERTS"
  export NETWORKING_POE_SSL_CERT_PEM=`echo $CERTIFICATES | jq --raw-output '.certificate'`
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=`echo $CERTIFICATES | jq --raw-output '.key'`

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$SECURITY_DOMAIN"`

  export UAA_CERT_PEM=`echo $CERTIFICATES | jq --raw-output '.certificate'`
  export UAA_PRIVATE_KEY_PEM=`echo $CERTIFICATES | jq --raw-output '.key'`


  echo "Using self signed certificates generated using Ops Manager..."
elif [[ "$NETWORKING_POE_SSL_CERT_PEM" =~ "\\r" ]]; then
  echo "No tweaking needed"
else
  export NETWORKING_POE_SSL_CERT_PEM=$(echo "$NETWORKING_POE_SSL_CERT_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=$(echo "$NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
  export UAA_CERT_PEM=$(echo "$UAA_CERT_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
  export UAA_PRIVATE_KEY_PEM=$(echo "$UAA_PRIVATE_KEY_PEM" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
fi


CF_PROPERTIES=$(jq -n \
  --arg allow_app_ssh_access $ALLOW_APP_SSH_ACCESS \
  --arg apps_domain $APPS_DOMAIN \
  --arg default_app_memory $DEFAULT_APP_MEMORY \
  --arg default_app_ssh_access $DEFAULT_APP_SSH_ACCESS \
  --arg default_disk_quota_app $DEFAULT_DISK_QUOTA_APP \
  --arg default_quota_max_number_services $DEFAULT_QUOTA_MAX_NUMBER_SERVICES \
  --arg default_quota_memory_limit_mb $DEFAULT_QUOTA_MEMORY_LIMIT_MB \
  --arg enable_custom_buildpacks $ENABLE_CUSTOM_BUILDPACKS \
  --arg encrypt_key $ENCRYPT_KEY \
  --arg max_disk_quota_app $MAX_DISK_QUOTA_APP \
  --arg max_file_size $MAX_FILE_SIZE \
  --arg security_event_logging_enabled $SECURITY_EVENT_LOGGING_ENABLED \
  --arg staging_timeout_in_seconds $STAGING_TIMEOUT_IN_SECONDS \
  --arg system_domain $SYSTEM_DOMAIN \
  --arg starting_container_count_maximum $STARTING_CONTAINER_COUNT_MAXIMUM \
  --arg static_ips $STATIC_IPS \
  --arg executor_disk_capacity $EXECUTOR_DISK_CAPACITY \
  --arg executor_memory_capacity $EXECUTOR_MEMORY_CAPACITY \
  --arg insecure_docker_registry_list $INSECURE_DOCKER_REGISTRY_LIST \
  --arg message_drain_buffer_size $MESSAGE_DRAIN_BUFFER_SIZE \
  --arg internal_only_domains $INTERNAL_ONLY_DOMAINS \
  --arg skip_cert_verify $SKIP_CERT_VERIFY \
  --arg static_ips $STATIC_IPS \
  --arg trusted_domain_cidrs $TRUSTED_DOMAIN_CIDRS \
  --arg cli_history $CLI_HISTORY \
  --arg cluster_probe_timeout $CLUSTER_PROBE_TIMEOUT \
  --arg prevent_node_auto_rejoin $PREVENT_NODE_AUTO_REJOIN \
  --arg remote_admin_access $REMOTE_ADMIN_ACCESS \
  --arg poll_frequency $POLL_FREQUENCY \
  --arg recipient_email $RECIPIENT_EMAIL \
  --arg write_read_delay $WRITE_READ_DELAY \
  --arg service_hostname $SERVICE_HOSTNAME \
  --arg shutdown_delay $SHUTDOWN_DELAY \
  --arg startup_delay $STARTUP_DELAY \
  --arg static_ips $STATIC_IPS \
  --arg blobstore_internal_access_rules $BLOBSTORE_INTERNAL_ACCESS_RULES \
  --arg autoscale_api_instance_count $AUTOSCALE_API_INSTANCE_COUNT \
  --arg autoscale_instance_count $AUTOSCALE_INSTANCE_COUNT \
  --arg autoscale_metric_bucket_count $AUTOSCALE_METRIC_BUCKET_COUNT \
  --arg autoscale_scaling_interval_in_seconds $AUTOSCALE_SCALING_INTERVAL_IN_SECONDS \
  --arg cc_api_rate_limit $CC_API_RATE_LIMIT \
  --arg cc_api_rate_limit_general_limit $CC_API_RATE_LIMIT_GENERAL_LIMIT \
  --arg cc_api_rate_limit_unauthenticated_limit $CC_API_RATE_LIMIT_UNAUTHENTICATED_LIMIT \
  --arg cf_dial_timeout_in_seconds $CF_DIAL_TIMEOUT_IN_SECONDS \
  --arg cf_networking_enable_space_developer_self_service $CF_NETWORKING_ENABLE_SPACE_DEVELOPER_SELF_SERVICE \
  --arg container_networking $CONTAINER_NETWORKING \
  --arg container_networking_interface_plugin $CONTAINER_NETWORKING_INTERFACE_PLUGIN \
  --arg dns_servers $DNS_SERVERS \
  --arg enable_log_traffic $ENABLE_LOG_TRAFFIC \
  --arg iptables_accepted_udp_logs_per_sec $IPTABLES_ACCEPTED_UDP_LOGS_PER_SEC \
  --arg iptables_denied_logs_per_sec $IPTABLES_DENIED_LOGS_PER_SEC \
  --arg network_cidr $NETWORK_CIDR \
  --arg network_mtu $NETWORK_MTU \
  --arg vtep_port $VTEP_PORT \
  --arg credhub_database $CREDHUB_DATABASE \
  --arg credhub_database_host $CREDHUB_DATABASE_HOST \
  --arg credhub_database_password $CREDHUB_DATABASE_PASSWORD \
  --arg credhub_database_port $CREDHUB_DATABASE_PORT \
  --arg credhub_database_tls_ca $CREDHUB_DATABASE_TLS_CA \
  --arg credhub_database_username $CREDHUB_DATABASE_USERNAME \
  --arg credhub_database_credhub_hsm_provider_client_certificate $CREDHUB_DATABASE_CREDHUB_HSM_PROVIDER_CLIENT_CERTIFICATE \
  --arg credhub_hsm_provider_partition $CREDHUB_HSM_PROVIDER_PARTITION \
  --arg credhub_hsm_provider_partition_password $CREDHUB_HSM_PROVIDER_PARTITION_PASSWORD \
  --arg credhub_hsm_provider_servers $CREDHUB_HSM_PROVIDER_SERVERS \
  --arg credhub_key_encryption_passwords $CREDHUB_KEY_ENCRYPTION_PASSWORDS \
  --arg credhub_key_encryption_name $CREDHUB_KEY_ENCRYPTION_NAME \
  --arg credhub_key_encryption_secret $CREDHUB_KEY_ENCRYPTION_SECRET \
  --arg credhub_key_encryption_is_primary $CREDHUB_KEY_ENCRYPTION_IS_PRIMARY \
  --arg enable_grootfs $ENABLE_GROOTFS \
  --arg enable_service_discovery_for_apps $ENABLE_SERVICE_DISCOVERY_FOR_APPS \
  --arg garden_disk_cleanup $GARDEN_DISK_CLEANUP \
  --arg gorouter_ssl_ciphers $GOROUTER_SSL_CIPHERS \
  --arg haproxy_forward_tls $HAPROXY_FORWARD_TLS \
  --arg haproxy_forward_tls_backend_ca $HAPROXY_FORWARD_TLS_BACKEND_CA \
  --arg haproxy_hsts_support $HAPROXY_HSTS_SUPPORT \
  --arg haproxy_hsts_support_enable_preload $HAPROXY_HSTS_SUPPORT_ENABLE_PRELOAD \
  --arg haproxy_hsts_support_include_subdomains $HAPROXY_HSTS_SUPPORT_INCLUDE_SUBDOMAINS \
  --arg haproxy_hsts_support_max_age $HAPROXY_HSTS_SUPPORT_MAX_AGE \
  --arg haproxy_max_buffer_size $HAPROXY_MAX_BUFFER_SIZE \
  --arg haproxy_ssl_ciphers $HAPROXY_SSL_CIPHERS \
  --arg logger_endpoint_port $LOGGER_ENDPOINT_PORT \
  --arg mysql_activity_logging $MYSQL_ACTIVITY_LOGGING \
  --arg audit_logging_events $AUDIT_LOGGING_EVENTS \
  --arg mysql_backups $MYSQL_BACKUPS \
  --arg backup_all_masters $BACKUP_ALL_MASTERS \
  --arg container $CONTAINER \
  --arg cron_schedule $CRON_SCHEDULE \
  --arg path $PATH \
  --arg storage_access_key $STORAGE_ACCESS_KEY \
  --arg storage_account $STORAGE_ACCOUNT \
  --arg backup_all_masters $BACKUP_ALL_MASTERS \
  --arg bucket_name $BUCKET_NAME \
  --arg cron_schedule $CRON_SCHEDULE \
  --arg project_id $PROJECT_ID \
  --arg service_account_json $SERVICE_ACCOUNT_JSON \
  --arg access_key_id $ACCESS_KEY_ID \
  --arg backup_all_masters $BACKUP_ALL_MASTERS \
  --arg bucket_name $BUCKET_NAME \
  --arg bucket_path $BUCKET_PATH \
  --arg cron_schedule $CRON_SCHEDULE \
  --arg endpoint_url $ENDPOINT_URL \
  --arg region $REGION \
  --arg secret_access_key $SECRET_ACCESS_KEY \
  --arg backup_all_masters $BACKUP_ALL_MASTERS \
  --arg cron_schedule $CRON_SCHEDULE \
  --arg destination $DESTINATION \
  --arg key $KEY \
  --arg port $PORT \
  --arg server $SERVER \
  --arg user $USER \
  --arg networking_poe_ssl_certs $NETWORKING_POE_SSL_CERTS \
  --arg nfs_volume_driver $NFS_VOLUME_DRIVER \
  --arg ldap_server_host $LDAP_SERVER_HOST \
  --arg ldap_server_port $LDAP_SERVER_PORT \
  --arg ldap_service_account_password $LDAP_SERVICE_ACCOUNT_PASSWORD \
  --arg ldap_service_account_user $LDAP_SERVICE_ACCOUNT_USER \
  --arg ldap_user_fqdn $LDAP_USER_FQDN \
  --arg push_apps_manager_accent_color $PUSH_APPS_MANAGER_ACCENT_COLOR \
  --arg push_apps_manager_company_name $PUSH_APPS_MANAGER_COMPANY_NAME \
  --arg push_apps_manager_currency_lookup $PUSH_APPS_MANAGER_CURRENCY_LOOKUP \
  --arg push_apps_manager_display_plan_prices $PUSH_APPS_MANAGER_DISPLAY_PLAN_PRICES \
  --arg push_apps_manager_enable_invitations $PUSH_APPS_MANAGER_ENABLE_INVITATIONS \
  --arg push_apps_manager_favicon $PUSH_APPS_MANAGER_FAVICON \
  --arg push_apps_manager_footer_links $PUSH_APPS_MANAGER_FOOTER_LINKS \
  --arg push_apps_manager_footer_text $PUSH_APPS_MANAGER_FOOTER_TEXT \
  --arg push_apps_manager_global_wrapper_bg_color $PUSH_APPS_MANAGER_GLOBAL_WRAPPER_BG_COLOR \
  --arg push_apps_manager_global_wrapper_footer_content $PUSH_APPS_MANAGER_GLOBAL_WRAPPER_FOOTER_CONTENT \
  --arg push_apps_manager_global_wrapper_header_content $PUSH_APPS_MANAGER_GLOBAL_WRAPPER_HEADER_CONTENT \
  --arg push_apps_manager_global_wrapper_text_color $PUSH_APPS_MANAGER_GLOBAL_WRAPPER_TEXT_COLOR \
  --arg push_apps_manager_logo $PUSH_APPS_MANAGER_LOGO \
  --arg push_apps_manager_marketplace_name $PUSH_APPS_MANAGER_MARKETPLACE_NAME \
  --arg push_apps_manager_nav_links $PUSH_APPS_MANAGER_NAV_LINKS \
  --arg push_apps_manager_product_name $PUSH_APPS_MANAGER_PRODUCT_NAME \
  --arg push_apps_manager_square_logo $PUSH_APPS_MANAGER_SQUARE_LOGO \
  --arg rep_proxy_enabled $REP_PROXY_ENABLED \
  --arg route_services $ROUTE_SERVICES \
  --arg ignore_ssl_cert_verification $IGNORE_SSL_CERT_VERIFICATION \
  --arg router_backend_max_conn $ROUTER_BACKEND_MAX_CONN \
  --arg router_client_cert_validation $ROUTER_CLIENT_CERT_VALIDATION \
  --arg router_enable_proxy $ROUTER_ENABLE_PROXY \
  --arg router_keepalive_connections $ROUTER_KEEPALIVE_CONNECTIONS \
  --arg routing_custom_ca_certificates $ROUTING_CUSTOM_CA_CERTIFICATES \
  --arg routing_disable_http $ROUTING_DISABLE_HTTP \
  --arg routing_minimum_tls_version $ROUTING_MINIMUM_TLS_VERSION \
  --arg routing_tls_termination $ROUTING_TLS_TERMINATION \
  --arg saml_entity_id_override $SAML_ENTITY_ID_OVERRIDE \
  --arg saml_signature_algorithm $SAML_SIGNATURE_ALGORITHM \
  --arg secure_service_instance_credentials $SECURE_SERVICE_INSTANCE_CREDENTIALS \
  --arg security_acknowledgement $SECURITY_ACKNOWLEDGEMENT \
  --arg smoke_tests $SMOKE_TESTS \
  --arg apps_domain $APPS_DOMAIN \
  --arg org_name $ORG_NAME \
  --arg space_name $SPACE_NAME \
  --arg smtp_address $SMTP_ADDRESS \
  --arg smtp_auth_mechanism $SMTP_AUTH_MECHANISM \
  --arg smtp_crammd5_secret $SMTP_CRAMMD5_SECRET \
  --arg smtp_credentials $SMTP_CREDENTIALS \
  --arg smtp_enable_starttls_auto $SMTP_ENABLE_STARTTLS_AUTO \
  --arg smtp_from $SMTP_FROM \
  --arg smtp_port $SMTP_PORT \
  --arg syslog_host $SYSLOG_HOST \
  --arg syslog_metrics_to_syslog_enabled $SYSLOG_METRICS_TO_SYSLOG_ENABLED \
  --arg syslog_port $SYSLOG_PORT \
  --arg syslog_protocol $SYSLOG_PROTOCOL \
  --arg syslog_rule $SYSLOG_RULE \
  --arg syslog_tls $SYSLOG_TLS \
  --arg tls_ca_cert $TLS_CA_CERT \
  --arg tls_permitted_peer $TLS_PERMITTED_PEER \
  --arg syslog_use_tcp_for_file_forwarding_local_transport $SYSLOG_USE_TCP_FOR_FILE_FORWARDING_LOCAL_TRANSPORT \
  --arg system_blobstore $SYSTEM_BLOBSTORE \
  --arg access_key $ACCESS_KEY \
  --arg buildpacks_bucket $BUILDPACKS_BUCKET \
  --arg droplets_bucket $DROPLETS_BUCKET \
  --arg encryption $ENCRYPTION \
  --arg encryption_kms_key_id $ENCRYPTION_KMS_KEY_ID \
  --arg endpoint $ENDPOINT \
  --arg packages_bucket $PACKAGES_BUCKET \
  --arg region $REGION \
  --arg resources_bucket $RESOURCES_BUCKET \
  --arg secret_key $SECRET_KEY \
  --arg signature_version $SIGNATURE_VERSION \
  --arg versioning $VERSIONING \
  --arg access_key $ACCESS_KEY \
  --arg account_name $ACCOUNT_NAME \
  --arg buildpacks_container $BUILDPACKS_CONTAINER \
  --arg droplets_container $DROPLETS_CONTAINER \
  --arg environment $ENVIRONMENT \
  --arg packages_container $PACKAGES_CONTAINER \
  --arg resources_container $RESOURCES_CONTAINER \
  --arg access_key $ACCESS_KEY \
  --arg buildpacks_bucket $BUILDPACKS_BUCKET \
  --arg droplets_bucket $DROPLETS_BUCKET \
  --arg packages_bucket $PACKAGES_BUCKET \
  --arg resources_bucket $RESOURCES_BUCKET \
  --arg secret_key $SECRET_KEY \
  --arg system_database $SYSTEM_DATABASE \
  --arg account_password $ACCOUNT_PASSWORD \
  --arg account_username $ACCOUNT_USERNAME \
  --arg app_usage_service_password $APP_USAGE_SERVICE_PASSWORD \
  --arg app_usage_service_username $APP_USAGE_SERVICE_USERNAME \
  --arg autoscale_password $AUTOSCALE_PASSWORD \
  --arg autoscale_username $AUTOSCALE_USERNAME \
  --arg ccdb_password $CCDB_PASSWORD \
  --arg ccdb_username $CCDB_USERNAME \
  --arg diego_password $DIEGO_PASSWORD \
  --arg diego_username $DIEGO_USERNAME \
  --arg host $HOST \
  --arg locket_password $LOCKET_PASSWORD \
  --arg locket_username $LOCKET_USERNAME \
  --arg networkpolicyserver_password $NETWORKPOLICYSERVER_PASSWORD \
  --arg networkpolicyserver_username $NETWORKPOLICYSERVER_USERNAME \
  --arg nfsvolume_password $NFSVOLUME_PASSWORD \
  --arg nfsvolume_username $NFSVOLUME_USERNAME \
  --arg notifications_password $NOTIFICATIONS_PASSWORD \
  --arg notifications_username $NOTIFICATIONS_USERNAME \
  --arg port $PORT \
  --arg routing_password $ROUTING_PASSWORD \
  --arg routing_username $ROUTING_USERNAME \
  --arg silk_password $SILK_PASSWORD \
  --arg silk_username $SILK_USERNAME \
  --arg tcp_routing $TCP_ROUTING \
  --arg reservable_ports $RESERVABLE_PORTS \
  --arg uaa $UAA \
  --arg password_expires_after_months $PASSWORD_EXPIRES_AFTER_MONTHS \
  --arg password_max_retry $PASSWORD_MAX_RETRY \
  --arg password_min_length $PASSWORD_MIN_LENGTH \
  --arg password_min_lowercase $PASSWORD_MIN_LOWERCASE \
  --arg password_min_numeric $PASSWORD_MIN_NUMERIC \
  --arg password_min_special $PASSWORD_MIN_SPECIAL \
  --arg password_min_uppercase $PASSWORD_MIN_UPPERCASE \
  --arg credentials $CREDENTIALS \
  --arg email_domains $EMAIL_DOMAINS \
  --arg first_name_attribute $FIRST_NAME_ATTRIBUTE \
  --arg group_search_base $GROUP_SEARCH_BASE \
  --arg group_search_filter $GROUP_SEARCH_FILTER \
  --arg last_name_attribute $LAST_NAME_ATTRIBUTE \
  --arg ldap_referrals $LDAP_REFERRALS \
  --arg mail_attribute_name $MAIL_ATTRIBUTE_NAME \
  --arg search_base $SEARCH_BASE \
  --arg search_filter $SEARCH_FILTER \
  --arg server_ssl_cert $SERVER_SSL_CERT \
  --arg server_ssl_cert_alias $SERVER_SSL_CERT_ALIAS \
  --arg url $URL \
  --arg display_name $DISPLAY_NAME \
  --arg email_attribute $EMAIL_ATTRIBUTE \
  --arg email_domains $EMAIL_DOMAINS \
  --arg entity_id_override $ENTITY_ID_OVERRIDE \
  --arg external_groups_attribute $EXTERNAL_GROUPS_ATTRIBUTE \
  --arg first_name_attribute $FIRST_NAME_ATTRIBUTE \
  --arg last_name_attribute $LAST_NAME_ATTRIBUTE \
  --arg name_id_format $NAME_ID_FORMAT \
  --arg require_signed_assertions $REQUIRE_SIGNED_ASSERTIONS \
  --arg sign_auth_requests $SIGN_AUTH_REQUESTS \
  --arg sso_name $SSO_NAME \
  --arg sso_url $SSO_URL \
  --arg sso_xml $SSO_XML \
  --arg uaa_database $UAA_DATABASE \
  --arg host $HOST \
  --arg port $PORT \
  --arg uaa_password $UAA_PASSWORD \
  --arg uaa_username $UAA_USERNAME \
  --arg disable_insecure_cookies $DISABLE_INSECURE_COOKIES \
  --arg drain_wait $DRAIN_WAIT \
  --arg enable_isolated_routing $ENABLE_ISOLATED_ROUTING \
  --arg enable_write_access_logs $ENABLE_WRITE_ACCESS_LOGS \
  --arg enable_zipkin $ENABLE_ZIPKIN \
  --arg extra_headers_to_log $EXTRA_HEADERS_TO_LOG \
  --arg frontend_idle_timeout $FRONTEND_IDLE_TIMEOUT \
  --arg lb_healthy_threshold $LB_HEALTHY_THRESHOLD \
  --arg request_timeout_in_seconds $REQUEST_TIMEOUT_IN_SECONDS \
  --arg static_ips $STATIC_IPS \
  --arg static_ips $STATIC_IPS \
  --arg apps_manager_access_token_lifetime $APPS_MANAGER_ACCESS_TOKEN_LIFETIME \
  --arg apps_manager_refresh_token_lifetime $APPS_MANAGER_REFRESH_TOKEN_LIFETIME \
  --arg cf_cli_access_token_lifetime $CF_CLI_ACCESS_TOKEN_LIFETIME \
  --arg cf_cli_refresh_token_lifetime $CF_CLI_REFRESH_TOKEN_LIFETIME \
  --arg customize_password_label $CUSTOMIZE_PASSWORD_LABEL \
  --arg customize_username_label $CUSTOMIZE_USERNAME_LABEL \
  --arg issuer_uri $ISSUER_URI \
  --arg proxy_ips_regex $PROXY_IPS_REGEX \
  --arg service_provider_key_credentials $SERVICE_PROVIDER_KEY_CREDENTIALS \
  --arg service_provider_key_password $SERVICE_PROVIDER_KEY_PASSWORD \
  '{
    ".properties.autoscale_api_instance_count": {
      "value": $autoscale_api_instance_count
    },
    ".properties.autoscale_instance_count": {
      "value": $autoscale_instance_count
    },
    ".properties.autoscale_metric_bucket_count": {
      "value": $autoscale_metric_bucket_count
    },
    ".properties.autoscale_scaling_interval_in_seconds": {
      "value": $autoscale_scaling_interval_in_seconds
    },
    ".properties.cc_api_rate_limit": {
      "value": $cc_api_rate_limit
    }
  }
  +
  if $cc_api_rate_limit == "enable" then
  {
    ".properties.cc_api_rate_limit.enable.general_limit": {
      "value": $cc_api_rate_limit_general_limit
    },
    ".properties.cc_api_rate_limit.enable.unauthenticated_limit": {
      "value": $cc_api_rate_limit_unauthenticated_limit
    }
  }
  else .
  end
  +
  {
    ".properties.cf_dial_timeout_in_seconds": {
      "value": $cf_dial_timeout_in_seconds
    },
    ".properties.cf_networking_enable_space_developer_self_service": {
      "value": $cf_networking_enable_space_developer_self_service
    },
    ".properties.container_networking": {
      "value": $container_networking
    },
    ".properties.container_networking_interface_plugin": {
      "value": $container_networking_interface_plugin
    }
  }
  +
  if $container_networking_interface_plugin == "silk" then
  {
    ".properties.container_networking_interface_plugin.silk.network_mtu": {
      "value": $network_mtu
    },
    ".properties.container_networking_interface_plugin.silk.network_cidr": {
      "value": $network_cidr
    },
    ".properties.container_networking_interface_plugin.silk.vtep_port": {
      "value": $vtep_port
    },
    ".properties.container_networking_interface_plugin.silk.iptables_denied_logs_per_sec": {
      "value": $iptables_denied_logs_per_sec
    },
    ".properties.container_networking_interface_plugin.silk.iptables_accepted_udp_logs_per_sec": {
      "value": $iptables_accepted_udp_logs_per_sec
    },
    ".properties.container_networking_interface_plugin.silk.enable_log_traffic": {
      "value": $enable_log_traffic
    },
    ".properties.container_networking_interface_plugin.silk.dns_servers": {
      "value": $dns_servers
    }
  }
  else .
  end
  +
  {
    ".properties.credhub_database": {
      "value": $credhub_database
    }
  }
  +
  if $credhub_database == "external" then
  {
    ".properties.credhub_database.external.host": {
      "value": $credhub_database_host
    },
    ".properties.credhub_database.external.port": {
      "value": $credhub_database_port
    },
    ".properties.credhub_database.external.username": {
      "value": $credhub_database_username
    },
    ".properties.credhub_database.external.password": {
      "value": {
        "secret": $credhub_database_password
      }
    },
    ".properties.credhub_database.external.tls_ca": {
      "value": $credhub_database_tls_ca
    },
    ".properties.credhub_hsm_provider_client_certificate": {
      "value": {
        "secret": $credhub_database_credhub_hsm_provider_client_certificate
      }
    }
  }
  else .
  end
  +
  {
    ".properties.credhub_hsm_provider_partition": {
      "value": $credhub_hsm_provider_partition
    },
    ".properties.credhub_hsm_provider_partition_password": {
      "secret": {
        "value": $credhub_hsm_provider_partition_password
      }
    },
    ".properties.credhub_hsm_provider_servers": {
      "value": $credhub_hsm_provider_servers
    },
    ".properties.credhub_key_encryption_passwords": {
      "value": [
        {
          "name": $credhub_key_encryption_name,
          "key" : { "secret": $credhub_key_encryption_secret },
          "primary": $credhub_key_encryption_is_primary
        }
      ]
    },
    ".properties.enable_grootfs": {
      "value": $enable_grootfs
    },
    ".properties.enable_service_discovery_for_apps": {
      "value": $enable_service_discovery_for_apps
    },
    ".properties.garden_disk_cleanup": {
      "value": $garden_disk_cleanup
    },
    ".properties.gorouter_ssl_ciphers": {
      "value": $gorouter_ssl_ciphers
    },
    ".properties.haproxy_forward_tls": {
      "value": $haproxy_forward_tls
    }
  }
  +
  if $haproxy_forward_tls == "enable" then
  {
    ".properties.haproxy_forward_tls.enable.backend_ca": {
      "value": $haproxy_forward_tls_backend_ca
    }
  }
  else .
  end
  +
  {
    ".properties.haproxy_hsts_support": {
      "value": $haproxy_hsts_support
    }
  }
  + if $haproxy_hsts_support == "enable" then
  {
    ".properties.haproxy_hsts_support.enable.max_age": {
      "value": $haproxy_hsts_support_max_age
    },
    ".properties.haproxy_hsts_support.enable.include_subdomains": {
      "value": $haproxy_hsts_support_include_subdomains
    },
    ".properties.haproxy_hsts_support.enable.enable_preload": {
      "value": $haproxy_hsts_support_enable_preload
    }
  }
  else .
  end
  +
  {
    ".properties.haproxy_max_buffer_size": {
      "value": $haproxy_max_buffer_size
    },
    ".properties.haproxy_ssl_ciphers": {
      "value": $haproxy_ssl_ciphers
    },
    ".properties.logger_endpoint_port": {
      "value": $logger_endpoint_port
    },
    ".properties.mysql_activity_logging": {
      "value": $mysql_activity_logging
    }
  }
  if $audit_logging_events == "enable" then
  {
    ".properties.mysql_activity_logging.enable.audit_logging_events": {
      "value": $audit_logging_events
    }
  }
  else .
  end
  {
    ".properties.mysql_backups": {
      "value": $mysql_backups
    }
  }
  if $mysql_backup == "s3" then
    ".properties.mysql_backups.s3.endpoint_url": {
      "value": $s3_endpoint_url
    },
    ".properties.mysql_backups.s3.bucket_name": {
      "value": $s3_bucket_name
    },
    ".properties.mysql_backups.s3.bucket_path": {
      "value": $s3_bucket_path
    },
    ".properties.mysql_backups.s3.access_key_id": {
      "value": $s3_access_key_id
    },
    ".properties.mysql_backups.s3.secret_access_key": {
      "value": {
        "secret": $s3_secret_access_key
      }
    },
    ".properties.mysql_backups.s3.cron_schedule": {
      "value": $s3_cron_schedule
    },
    ".properties.mysql_backups.s3.backup_all_masters": {
      "value": $s3_backup_all_masters
    },
    ".properties.mysql_backups.s3.region": {
      "value": $s3_region
    }
  }
  elif $mysql_backup == "gcs" then
  {
    ".properties.mysql_backups.gcs.service_account_json": {
      "value": {
        "secret": $gcs_service_account_json
      }
    },
    ".properties.mysql_backups.gcs.project_id": {
      "value": $gcs_project_id
    },
    ".properties.mysql_backups.gcs.bucket_name": {
      "value": $gcs_bucket_name
    },
    ".properties.mysql_backups.gcs.cron_schedule": {
      "value": $gcs_cron_schedule
    },
    ".properties.mysql_backups.gcs.backup_all_masters": {
      "value": $gcs_backup_all_masters
    }
  }
  elif $mysql_backup == "azure" then
  {
    ".properties.mysql_backups.azure.storage_account": {
      "value": $azure_storage_account
    },
    ".properties.mysql_backups.azure.storage_access_key": {
      "value": {
        "secret": $azure_storage_access_key
      }
    },
    ".properties.mysql_backups.azure.container": {
      "value": $azure_container
    },
    ".properties.mysql_backups.azure.path": {
      "value": $azure_path
    },
    ".properties.mysql_backups.azure.cron_schedule": {
      "value": $azure_cron_schedule
    },
    ".properties.mysql_backups.azure.backup_all_masters": {
      "value": $azure_backup_all_masters
    }
  }
  elif $mysql_backup == "scp"
  {
    ".properties.mysql_backups.scp.server": {
      "value": $scp_server
    },
    ".properties.mysql_backups.scp.port": {
      "value": $scp_port
    },
    ".properties.mysql_backups.scp.user": {
      "value": $scp_user
    },
    ".properties.mysql_backups.scp.key": {
      "value": $scp_key
    },
    ".properties.mysql_backups.scp.destination": {
      "value": $scp_destination
    },
    ".properties.mysql_backups.scp.cron_schedule": {
      "value": $scp_cron_schedule
    },
    ".properties.mysql_backups.scp.backup_all_masters": {
      "value": $scp_backup_all_masters
    }
  }
  else .
  end
  +
  {
    ".properties.networking_poe_ssl_certs": {
      "value": $networking_poe_ssl_certs
    },
    ".properties.nfs_volume_driver": {
      "value": $nfs_volume_driver
    }
  }
  +
  if $nfs_volume_driver == "enable" then
  {
    ".properties.nfs_volume_driver.enable.ldap_service_account_user": {
      "value": $nfs_volume_driver_ldap_service_account_user
    },
    ".properties.nfs_volume_driver.enable.ldap_service_account_password": {
      "value": {
        "secret": $nfs_volume_driver_ldap_service_account_password
      }
    },
    ".properties.nfs_volume_driver.enable.ldap_server_host": {
      "value": $nfs_volume_driver_ldap_server_host
    },
    ".properties.nfs_volume_driver.enable.ldap_server_port": {
      "value": $nfs_volume_driver_ldap_server_port
    },
    ".properties.nfs_volume_driver.enable.ldap_user_fqdn": {
      "value": $nfs_volume_driver_ldap_user_fqdn
    }
  }
  else .
  end
  +
  {
    ".properties.push_apps_manager_accent_color": {
      "value": $push_apps_manager_accent_color
    },
    ".properties.push_apps_manager_company_name": {
      "value": $push_apps_manager_company_name
    },
    ".properties.push_apps_manager_currency_lookup": {
      "value": $push_apps_manager_currency_lookup
    },
    ".properties.push_apps_manager_display_plan_prices": {
      "value": $push_apps_manager_display_plan_prices
    },
    ".properties.push_apps_manager_enable_invitations": {
      "value": $push_apps_manager_enable_invitations
    },
    ".properties.push_apps_manager_favicon": {
      "value": $push_apps_manager_favicon
    },
    ".properties.push_apps_manager_footer_links": {
      "value": $push_apps_manager_footer_links
    },
    ".properties.push_apps_manager_footer_text": {
      "value": $push_apps_manager_footer_text
    },
    ".properties.push_apps_manager_global_wrapper_bg_color": {
      "value": $push_apps_manager_global_wrapper_bg_color
    },
    ".properties.push_apps_manager_global_wrapper_footer_content": {
      "value": $push_apps_manager_global_wrapper_footer_content
    },
    ".properties.push_apps_manager_global_wrapper_header_content": {
      "value": $push_apps_manager_global_wrapper_header_content
    },
    ".properties.push_apps_manager_global_wrapper_text_color": {
      "value": $push_apps_manager_global_wrapper_text_color
    },
    ".properties.push_apps_manager_logo": {
      "value": $push_apps_manager_logo
    },
    ".properties.push_apps_manager_marketplace_name": {
      "value": $push_apps_manager_marketplace_name
    },
    ".properties.push_apps_manager_nav_links": {
      "value": $push_apps_manager_nav_links
    },
    ".properties.push_apps_manager_product_name": {
      "value": $push_apps_manager_product_name
    },
    ".properties.push_apps_manager_square_logo": {
      "value": $push_apps_manager_square_logo
    },
    ".properties.rep_proxy_enabled": {
      "value": $rep_proxy_enabled
    },
    ".properties.route_services": {
      "value": $route_services
    }
  }
  if $route_services == "enable" then
  {
    ".properties.route_services.enable.ignore_ssl_cert_verification": {
      "value": $route_services_ignore_ssl_cert_verification
    }
  }
  else .
  end
  +
  {
    ".properties.router_backend_max_conn": {
      "value": $router_backend_max_conn
    },
    ".properties.router_client_cert_validation": {
      "value": $router_client_cert_validation
    },
    ".properties.router_enable_proxy": {
      "value": $router_enable_proxy
    },
    ".properties.router_keepalive_connections": {
      "value": $router_keepalive_connections
    },
    ".properties.routing_custom_ca_certificates": {
      "value": $routing_custom_ca_certificates
    },
    ".properties.routing_disable_http": {
      "value": $routing_disable_http
    },
    ".properties.routing_minimum_tls_version": {
      "value": $routing_minimum_tls_version
    },
    ".properties.routing_tls_termination": {
      "value": $routing_tls_termination
    },
    ".properties.saml_entity_id_override": {
      "value": $saml_entity_id_override
    },
    ".properties.saml_signature_algorithm": {
      "value": $saml_signature_algorithm
    },
    ".properties.secure_service_instance_credentials": {
      "value": $secure_service_instance_credentials
    },
    ".properties.security_acknowledgement": {
      "value": $security_acknowledgement
    },
    ".properties.smoke_tests": {
      "value": $smoke_tests
    }
  }
  +
  if $smoke_tests == "specified" then
  {
    ".properties.smoke_tests.specified.org_name": {
      "value": $smoke_tests_org_name
    },
    ".properties.smoke_tests.specified.space_name": {
      "value": $smoke_tests_space_name
    },
    ".properties.smoke_tests.specified.apps_domain": {
      "value": $smoke_tests_apps_domain
    }
  }
  else .
  end
  +
  {
    ".properties.smtp_address": {
      "value": $smtp_address
    },
    ".properties.smtp_auth_mechanism": {
      "value": $smtp_auth_mechanism
    },
    ".properties.smtp_crammd5_secret": {
      "value": $smtp_crammd5_secret
    },
    ".properties.smtp_credentials": {
      "value": {
        "secret": $smtp_credentials
      }
    },
    ".properties.smtp_enable_starttls_auto": {
      "value": $smtp_enable_starttls_auto
    },
    ".properties.smtp_from": {
      "value": $smtp_from
    },
    ".properties.smtp_port": {
      "value": $smtp_port
    },
    ".properties.syslog_host": {
      "value": $syslog_host
    },
    ".properties.syslog_metrics_to_syslog_enabled": {
      "value": $syslog_metrics_to_syslog_enabled
    },
    ".properties.syslog_port": {
      "value": $syslog_port
    },
    ".properties.syslog_protocol": {
      "value": $syslog_protocol
    },
    ".properties.syslog_rule": {
      "value": $syslog_rule
    },
    ".properties.syslog_tls": {
      "value": $syslog_tls
    }
  }
  +
  if $syslog_tls == "enabled" then
  {
    ".properties.syslog_tls.enabled.tls_ca_cert": {
      "value": $syslog_tls_tls_ca_cert
    },
    ".properties.syslog_tls.enabled.tls_permitted_peer": {
      "value": $syslog_tls_tls_permitted_peer
    }
  }
  else .
  end
  +
  {
    ".properties.syslog_use_tcp_for_file_forwarding_local_transport": {
      "value": $syslog_use_tcp_for_file_forwarding_local_transport
    },
    ".properties.system_blobstore": {
      "value": $system_blobstore
    }
  }
  +
  if $system_blobstore == "external" then
  {
    ".properties.system_blobstore.external.endpoint": {
      "value": $system_blobstore_external_endpoint
    },
    ".properties.system_blobstore.external.buildpacks_bucket": {
      "value": $system_blobstore_external_buildpacks_bucket
    },
    ".properties.system_blobstore.external.droplets_bucket": {
      "value": $system_blobstore_external_droplets_bucket
    },
    ".properties.system_blobstore.external.packages_bucket": {
      "value": $system_blobstore_external_packages_bucket
    },
    ".properties.system_blobstore.external.resources_bucket": {
      "value": $system_blobstore_external_resources_bucket
    },
    ".properties.system_blobstore.external.access_key": {
      "value": $system_blobstore_external_access_key
    },
    ".properties.system_blobstore.external.secret_key": {
      "value": {
        "secret": $system_blobstore_external_secret_key
      }
    },
    ".properties.system_blobstore.external.signature_version": {
      "value": $system_blobstore_external_signature_version
    },
    ".properties.system_blobstore.external.region": {
      "value": $system_blobstore_external_region
    },
    ".properties.system_blobstore.external.encryption": {
      "value": $system_blobstore_external_encryption
    },
    ".properties.system_blobstore.external.encryption_kms_key_id": {
      "value": $system_blobstore_external_encryption_kms_key_id
    },
    ".properties.system_blobstore.external.versioning": {
      "value": $system_blobstore_external_versioning
    }
  }
  elif $system_blobstore == "external_gcs" then
  {
    ".properties.system_blobstore.external_gcs.buildpacks_bucket": {
      "value": $system_blobstore_external_gcs_buildpacks_bucket
    },
    ".properties.system_blobstore.external_gcs.droplets_bucket": {
      "value": $system_blobstore_external_gcs_droplets_bucket
    },
    ".properties.system_blobstore.external_gcs.packages_bucket": {
      "value": $system_blobstore_external_gcs_packages_bucket
    },
    ".properties.system_blobstore.external_gcs.resources_bucket": {
      "value": $system_blobstore_external_gcs_resources_bucket
    },
    ".properties.system_blobstore.external_gcs.access_key": {
      "value": $system_blobstore_external_gcs_access_key
    },
    ".properties.system_blobstore.external_gcs.secret_key": {
      "value": {
        "secret": $system_blobstore_external_gcs_secret_key
      }
    }
  }
  elif $system_blobstore == "external_azure" then
  {
    ".properties.system_blobstore.external_azure.buildpacks_container": {
      "value": $system_blobstore_external_azure_buildpacks_container
    },
    ".properties.system_blobstore.external_azure.droplets_container": {
      "value": $system_blobstore_external_azure_droplets_container
    },
    ".properties.system_blobstore.external_azure.packages_container": {
      "value": $system_blobstore_external_azure_packages_container
    },
    ".properties.system_blobstore.external_azure.resources_container": {
      "value": $system_blobstore_external_azure_resources_container
    },
    ".properties.system_blobstore.external_azure.account_name": {
      "value": $system_blobstore_external_azure_account_name
    },
    ".properties.system_blobstore.external_azure.access_key": {
      "value": {
        "secret": $system_blobstore_external_azure_access_key
      }
    },
    ".properties.system_blobstore.external_azure.environment": {
      "value": $system_blobstore_external_azure_environment
    }
  }
  else .
  end
  +
  {
    ".properties.system_database": {
      "value": $system_database
    }
  }
  +
  if $system_database == "external" then
  {
    ".properties.system_database.external.host": {
      "value": $system_database_external_host
    },
    ".properties.system_database.external.port": {
      "value": $system_database_external_port
    },
    ".properties.system_database.external.account_username": {
      "value": $system_database_external_account_username
    },
    ".properties.system_database.external.account_password": {
      "value": {
        "secret": $system_database_external_account_password
      }
    },
    ".properties.system_database.external.app_usage_service_username": {
      "value": $system_database_external_app_usage_service_username
    },
    ".properties.system_database.external.app_usage_service_password": {
      "value": {
        "secret": $system_database_external_app_usage_service_password
      }
    },
    ".properties.system_database.external.autoscale_username": {
      "value": $system_database_external_autoscale_username
    },
    ".properties.system_database.external.autoscale_password": {
      "value": {
        "secret": $system_database_external_autoscale_password
      }
    },
    ".properties.system_database.external.ccdb_username": {
      "value": $system_database_external_ccdb_username
    },
    ".properties.system_database.external.ccdb_password": {
      "value": {
        "secret": $system_database_external_ccdb_password
      }
    },
    ".properties.system_database.external.diego_username": {
      "value": $system_database_external_diego_username
    },
    ".properties.system_database.external.diego_password": {
      "value": {
        "secret": $system_database_external_diego_password
      }
    },
    ".properties.system_database.external.locket_username": {
      "value": $system_database_external_locket_username
    },
    ".properties.system_database.external.locket_password": {
      "value": {
        "secret": $system_database_external_locket_password
      }
    },
    ".properties.system_database.external.networkpolicyserver_username": {
      "value": $system_database_external_networkpolicyserver_username
    },
    ".properties.system_database.external.networkpolicyserver_password": {
      "value": {
        "secret": $system_database_external_networkpolicyserver_password
      }
    },
    ".properties.system_database.external.nfsvolume_username": {
      "value": $system_database_external_nfsvolume_username
    },
    ".properties.system_database.external.nfsvolume_password": {
      "value": {
        "secret": $system_database_external_nfsvolume_password
      }
    },
    ".properties.system_database.external.notifications_username": {
      "value": $system_database_external_notifications_username
    },
    ".properties.system_database.external.notifications_password": {
      "value": {
        "secret": $system_database_external_notifications_password
      }
    },
    ".properties.system_database.external.routing_username": {
      "value": $system_database_external_routing_username
    },
    ".properties.system_database.external.routing_password": {
      "value": {
        "secret": $system_database_external_routing_password
      }
    },
    ".properties.system_database.external.silk_username": {
      "value": $system_database_external_silk_username
    },
    ".properties.system_database.external.silk_password": {
      "value": {
        "secret": $system_database_external_silk_password
      }
    }
  }
  else .
  end
  +
  {
    ".properties.tcp_routing": {
      "value": $tcp_routing
    }
  }
  +
  if $tcp_routing == "enable" then
  {
    ".properties.tcp_routing.enable.reservable_ports": {
      "value": $tcp_routing_reservable_ports
    }
  }
  else .
  end
  +
  {
    ".properties.uaa": {
      "value": $uaa
    }
  }
  +
  if $uaa == "internal" then
  {
    ".properties.uaa.internal.password_min_length": {
      "value": $uaa_internal_password_min_length
    },
    ".properties.uaa.internal.password_min_uppercase": {
      "value": $uaa_internal_password_min_uppercase
    },
    ".properties.uaa.internal.password_min_lowercase": {
      "value": $uaa_internal_password_min_lowercase
    },
    ".properties.uaa.internal.password_min_numeric": {
      "value": $uaa_internal_password_min_numeric
    },
    ".properties.uaa.internal.password_min_special": {
      "value": $uaa_internal_password_min_special
    },
    ".properties.uaa.internal.password_expires_after_months": {
      "value": $uaa_internal_password_expires_after_months
    },
    ".properties.uaa.internal.password_max_retry": {
      "value": $uaa_internal_password_max_retry
    }
  }
  elif $uaa == "saml" then
  {
    ".properties.uaa.saml.sso_name": {
      "value": $uaa_saml_sso_name
    },
    ".properties.uaa.saml.display_name": {
      "value": $uaa_saml_display_name
    },
    ".properties.uaa.saml.sso_url": {
      "value": $uaa_saml_sso_url
    },
    ".properties.uaa.saml.name_id_format": {
      "value": $uaa_saml_name_id_format
    },
    ".properties.uaa.saml.sso_xml": {
      "value": $uaa_saml_sso_xml
    },
    ".properties.uaa.saml.sign_auth_requests": {
      "value": $uaa_saml_sign_auth_requests
    },
    ".properties.uaa.saml.require_signed_assertions": {
      "value": $uaa_saml_require_signed_assertions
    },
    ".properties.uaa.saml.email_domains": {
      "value": $uaa_saml_email_domains
    },
    ".properties.uaa.saml.first_name_attribute": {
      "value": $uaa_saml_first_name_attribute
    },
    ".properties.uaa.saml.last_name_attribute": {
      "value": $uaa_saml_last_name_attribute
    },
    ".properties.uaa.saml.email_attribute": {
      "value": $uaa_saml_email_attribute
    },
    ".properties.uaa.saml.external_groups_attribute": {
      "value": $uaa_saml_external_groups_attribute
    },
    ".properties.uaa.saml.entity_id_override": {
      "value": $uaa_saml_entity_id_override
    }
  }
  elif $uaa == "ldap" then
  {
    ".properties.uaa.ldap.url": {
      "value": $uaa_ldap_url
    },
    ".properties.uaa.ldap.credentials": {
      "value": {
        "identity": $uaa_ldap_ldap_identity,
        "password": $uaa_ldap_ldap_password
      }
    },
    ".properties.uaa.ldap.search_base": {
      "value": $uaa_ldap_search_base
    },
    ".properties.uaa.ldap.search_filter": {
      "value": $uaa_ldap_search_filter
    },
    ".properties.uaa.ldap.group_search_base": {
      "value": $uaa_ldap_group_search_base
    },
    ".properties.uaa.ldap.group_search_filter": {
      "value": $uaa_ldap_group_search_filter
    },
    ".properties.uaa.ldap.server_ssl_cert": {
      "value": $uaa_ldap_server_ssl_cert
    },
    ".properties.uaa.ldap.server_ssl_cert_alias": {
      "value": $uaa_ldap_server_ssl_cert_alias
    },
    ".properties.uaa.ldap.mail_attribute_name": {
      "value": $uaa_ldap_mail_attribute_name
    },
    ".properties.uaa.ldap.email_domains": {
      "value": $uaa_ldap_email_domains
    },
    ".properties.uaa.ldap.first_name_attribute": {
      "value": $uaa_ldap_first_name_attribute
    },
    ".properties.uaa.ldap.last_name_attribute": {
      "value": $uaa_ldap_last_name_attribute
    },
    ".properties.uaa.ldap.ldap_referrals": {
      "value": $uaa_ldap_ldap_referrals
    }
  }
  else .
  end
  +
  {
    ".properties.uaa_database": {
      "value": $uaa_database
    }
  }
  +
  if $uaa_database == "external" then
  {
    ".properties.uaa_database.external.host": {
      "value": $uaa_database_external_host
    },
    ".properties.uaa_database.external.port": {
      "value": $uaa_database_external_port
    },
    ".properties.uaa_database.external.uaa_username": {
      "value": $uaa_database_external_uaa_username
    },
    ".properties.uaa_database.external.uaa_password": {
      "value": {
        "secret": $uaa_database_external_uaa_password
      }
    }
  }
  else .
  end
  +
  {
    ".nfs_server.blobstore_internal_access_rules": {
      "value": $nfs_server_blobstore_internal_access_rules
    },
    ".mysql_proxy.static_ips": {
      "value": $mysql_proxy_static_ips
    },
    ".mysql_proxy.service_hostname": {
      "value": $mysql_proxy_service_hostname
    },
    ".mysql_proxy.startup_delay": {
      "value": $mysql_proxy_startup_delay
    },
    ".mysql_proxy.shutdown_delay": {
      "value": $mysql_proxy_shutdown_delay
    },
    ".mysql.cli_history": {
      "value": $mysql_cli_history
    },
    ".mysql.cluster_probe_timeout": {
      "value": $mysql_cluster_probe_timeout
    },
    ".mysql.prevent_node_auto_rejoin": {
      "value": $mysql_prevent_node_auto_rejoin
    },
    ".mysql.remote_admin_access": {
      "value": $mysql_remote_admin_access
    },
    ".uaa.service_provider_key_credentials": {
      "value": {
        "private_key_pem": $uaa_private_key_pem,
        "cert_pem": $uaa_cert_pem
      }
    },
    ".uaa.service_provider_key_password": {
      "value": {
        "secret": $uaa_service_provider_key_password
      }
    },
    ".uaa.apps_manager_access_token_lifetime": {
      "value": $uaa_apps_manager_access_token_lifetime
    },
    ".uaa.apps_manager_refresh_token_lifetime": {
      "value": $uaa_apps_manager_refresh_token_lifetime
    },
    ".uaa.cf_cli_access_token_lifetime": {
      "value": $uaa_cf_cli_access_token_lifetime
    },
    ".uaa.cf_cli_refresh_token_lifetime": {
      "value": $uaa_cf_cli_refresh_token_lifetime
    },
    ".uaa.customize_username_label": {
      "value": $uaa_customize_username_label
    },
    ".uaa.customize_password_label": {
      "value": $uaa_customize_password_label
    },
    ".uaa.proxy_ips_regex": {
      "value": $uaa_proxy_ips_regex
    },
    ".uaa.issuer_uri": {
      "value": $uaa_issuer_uri
    },
    ".cloud_controller.encrypt_key": {
      "value": {
        "secret": $cloud_controller_encrypt_key
      }
    },
    ".cloud_controller.max_file_size": {
      "value": $cloud_controller_max_file_size
    },
    ".cloud_controller.default_app_memory": {
      "value": $cloud_controller_default_app_memory
    },
    ".cloud_controller.max_disk_quota_app": {
      "value": $cloud_controller_max_disk_quota_app
    },
    ".cloud_controller.default_disk_quota_app": {
      "value": $cloud_controller_default_disk_quota_app
    },
    ".cloud_controller.enable_custom_buildpacks": {
      "value": $cloud_controller_enable_custom_buildpacks
    },
    ".cloud_controller.system_domain": {
      "value": $cloud_controller_system_domain
    },
    ".cloud_controller.apps_domain": {
      "value": $cloud_controller_apps_domain
    },
    ".cloud_controller.default_quota_memory_limit_mb": {
      "value": $cloud_controller_default_quota_memory_limit_mb
    },
    ".cloud_controller.default_quota_max_number_services": {
      "value": $cloud_controller_default_quota_max_number_services
    },
    ".cloud_controller.staging_timeout_in_seconds": {
      "value": $cloud_controller_staging_timeout_in_seconds
    },
    ".cloud_controller.allow_app_ssh_access": {
      "value": $cloud_controller_allow_app_ssh_access
    },
    ".cloud_controller.default_app_ssh_access": {
      "value": $cloud_controller_default_app_ssh_access
    },
    ".cloud_controller.security_event_logging_enabled": {
      "value": $cloud_controller_security_event_logging_enabled
    },
    ".ha_proxy.static_ips": {
      "value": $ha_proxy_static_ips
    },
    ".ha_proxy.skip_cert_verify": {
      "value": $ha_proxy_skip_cert_verify
    },
    ".ha_proxy.internal_only_domains": {
      "value": $ha_proxy_internal_only_domains
    },
    ".ha_proxy.trusted_domain_cidrs": {
      "value": $ha_proxy_trusted_domain_cidrs
    },
    ".router.static_ips": {
      "value": $router_static_ips
    },
    ".router.disable_insecure_cookies": {
      "value": $router_disable_insecure_cookies
    },
    ".router.request_timeout_in_seconds": {
      "value": $router_request_timeout_in_seconds
    },
    ".router.frontend_idle_timeout": {
      "value": $router_frontend_idle_timeout
    },
    ".router.drain_wait": {
      "value": $router_drain_wait
    },
    ".router.lb_healthy_threshold": {
      "value": $router_lb_healthy_threshold
    },
    ".router.enable_zipkin": {
      "value": $router_enable_zipkin
    },
    ".router.enable_write_access_logs": {
      "value": $router_enable_write_access_logs
    },
    ".router.extra_headers_to_log": {
      "value": $router_extra_headers_to_log
    },
    ".router.enable_isolated_routing": {
      "value": $router_enable_isolated_routing
    },
    ".mysql_monitor.poll_frequency": {
      "value": $mysql_monitor_poll_frequency
    },
    ".mysql_monitor.write_read_delay": {
      "value": $mysql_monitor_write_read_delay
    },
    ".mysql_monitor.recipient_email": {
      "value": $mysql_monitor_recipient_email
    },
    ".diego_brain.static_ips": {
      "value": $diego_brain_static_ips
    },
    ".diego_brain.starting_container_count_maximum": {
      "value": $diego_brain_starting_container_count_maximum
    },
    ".diego_cell.executor_disk_capacity": {
      "value": $diego_cell_executor_disk_capacity
    },
    ".diego_cell.executor_memory_capacity": {
      "value": $diego_cell_executor_memory_capacity
    },
    ".diego_cell.insecure_docker_registry_list": {
      "value": $diego_cell_insecure_docker_registry_list
    },
    ".doppler.message_drain_buffer_size": {
      "value": $doppler_message_drain_buffer_size
    },
    ".tcp_router.static_ips": {
      "value": $tcp_router_static_ips
    }
  }'
)


CF_RESOURCES=$(cat <<-EOF
{
  "consul_server": {
    "instance_type": {"id": "$CONSUL_SERVER_INSTANCE_TYPE"},
    "instances" : $CONSUL_SERVER_INSTANCES,
    "persistent_disk": { "size_mb": "$CONSUL_SERVER_PERSISTENT_DISK_SIZE_MB" }
  },
  "nats": {
    "instance_type": {"id": "$NATS_INSTANCE_TYPE"},
    "instances" : $NATS_INSTANCES
  },
  "nfs_server": {
    "instance_type": {"id": "$NFS_SERVER_INSTANCE_TYPE"},
    "instances" : $NFS_SERVER_INSTANCES,
    "persistent_disk": { "size_mb": "$NFS_SERVER_PERSISTENT_DISK_SIZE_MB" }
  },
  "mysql_proxy": {
    "instance_type": {"id": "$MYSQL_PROXY_INSTANCE_TYPE"},
    "instances" : $MYSQL_PROXY_INSTANCES
  },
  "mysql": {
    "instance_type": {"id": "$MYSQL_INSTANCE_TYPE"},
    "instances" : $MYSQL_INSTANCES,
    "persistent_disk": { "size_mb": "$MYSQL_INSTANCE_PERSISTENT_DISK_SIZE_MB" }
  },
  "backup-prepare": {
    "instance_type": {"id": "$BACKUP_PREPARE_INSTANCE_TYPE"},
    "instances" : $BACKUP_PREPARE_INSTANCES,
    "persistent_disk": { "size_mb": "$BACKUP_PREPARE_PERSISTENT_DISK_SIZE_MB" }
  },
  "uaa": {
    "instance_type": {"id": "$UAA_INSTANCE_TYPE"},
    "instances" : $UAA_INSTANCES
  },
  "cloud_controller": {
    "instance_type": {"id": "$CLOUD_CONTROLLER_INSTANCE_TYPE"},
    "instances" : $CLOUD_CONTROLLER_INSTANCES
  },
  "ha_proxy": {
    "instance_type": {"id": "$HA_PROXY_INSTANCE_TYPE"},
    "instances" : $HA_PROXY_INSTANCES
  },
  "router": {
    "instance_type": {"id": "$ROUTER_INSTANCE_TYPE"},
    "instances" : $ROUTER_INSTANCES
  },
  "mysql_monitor": {
    "instance_type": {"id": "$MYSQL_MONITOR_INSTANCE_TYPE"},
    "instances" : $MYSQL_MONITOR_INSTANCES
  },
  "clock_global": {
    "instance_type": {"id": "$CLOCK_GLOBAL_INSTANCE_TYPE"},
    "instances" : $CLOCK_GLOBAL_INSTANCES
  },
  "cloud_controller_worker": {
    "instance_type": {"id": "$CLOUD_CONTROLLER_WORKER_INSTANCE_TYPE"},
    "instances" : $CLOUD_CONTROLLER_WORKER_INSTANCES
  },
  "diego_database": {
    "instance_type": {"id": "$DIEGO_DATABASE_INSTANCE_TYPE"},
    "instances" : $DIEGO_DATABASE_INSTANCES
  },
  "diego_brain": {
    "instance_type": {"id": "$DIEGO_BRAIN_INSTANCE_TYPE"},
    "instances" : $DIEGO_BRAIN_INSTANCES,
    "persistent_disk": { "size_mb": "$DIEGO_BRAIN_PERSISTENT_DISK_SIZE_MB" }
  },
  "diego_cell": {
    "instance_type": {"id": "$DIEGO_CELL_INSTANCE_TYPE"},
    "instances" : $DIEGO_CELL_INSTANCES
  },
  "doppler": {
    "instance_type": {"id": "$DOPPLER_INSTANCE_TYPE"},
    "instances" : $DOPPLER_INSTANCES
  },
  "loggregator_trafficcontroller": {
    "instance_type": {"id": "$LOGGREGATOR_TC_INSTANCE_TYPE"},
    "instances" : $LOGGREGATOR_TC_INSTANCES
  },
  "tcp_router": {
    "instance_type": {"id": "$TCP_ROUTER_INSTANCE_TYPE"},
    "instances" : $TCP_ROUTER_INSTANCES,
    "persistent_disk": { "size_mb": "$TCP_ROUTER_PERSISTENT_DISK_SIZE_MB" }
  },
  "syslog_adapter": {
    "instance_type": {"id": "$SYSLOG_ADAPTER_INSTANCE_TYPE"},
    "instances" : $SYSLOG_ADAPTER_INSTANCES
  },
  "syslog_scheduler": {
    "instance_type": {"id": "$SYSLOG_SCHEDULER_INSTANCE_TYPE"},
    "instances" : $SYSLOG_SCHEDULER_INSTANCES
  },
  "credhub": {
    "instance_type": {"id": "$CREDHUB_INSTANCE_TYPE"},
    "instances" : $CREDHUB_INSTANCES
  }
}
EOF
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_PROPERTIES" -pn "$CF_NETWORK" -pr "$CF_RESOURCES"
