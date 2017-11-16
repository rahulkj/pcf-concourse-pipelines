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
    "name": "$ERT_SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $ERT_AZS
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


CF_PROPERTIES=$(
  echo "{}" |
  $JQ_CMD -n \
    --arg cc_api_rate_limit "$CC_API_RATE_LIMIT" \
    --arg general_limit "$GENERAL_LIMIT" \
    --arg unauthenticated_limit "$UNAUTHENTICATED_LIMIT" \
    --arg credhub_key_encryption_password "$CREDHUB_KEY_ENCRYPTION_PASSWORD" \
    --argjson secure_service_instance_credentials "$SECURE_SERVICE_INSTANCE_CREDENTIALS" \
    --arg credhub_database "$CREDHUB_DATABASE" \
    --arg credhub_database_external_host "$CREDHUB_DATABASE_EXTERNAL_HOST" \
    --arg credhub_database_external_port "$CREDHUB_DATABASE_EXTERNAL_PORT" \
    --arg credhub_database_external_username "$CREDHUB_DATABASE_EXTERNAL_USERNAME" \
    --arg credhub_database_external_password "$CREDHUB_DATABASE_EXTERNAL_PASSWORD" \
    --arg credhub_database_external_tls_ca "$CREDHUB_DATABASE_EXTERNAL_TLS_CA" \
    --arg nfs_volume_driver "$NFS_VOLUME_DRIVER" \
    --arg ldap_service_account_user "$LDAP_SERVICE_ACCOUNT_USER" \
    --arg ldap_service_account_password "$LDAP_SERVICE_ACCOUNT_PASSWORD" \
    --arg ldap_server_host "$LDAP_SERVER_HOST" \
    --arg ldap_server_port "$LDAP_SERVER_PORT" \
    --arg ldap_user_fqdn "$LDAP_USER_FQDN" \
    --arg garden_disk_cleanup "$GARDEN_DISK_CLEANUP" \
    --arg enable_grootfs "$ENABLE_GROOTFS" \
    --arg logger_endpoint_port "$LOGGER_ENDPOINT_PORT" \
    --arg syslog_host "$SYSLOG_HOST" \
    --arg syslog_port "$SYSLOG_PORT" \
    --arg syslog_protocol "$SYSLOG_PROTOCOL" \
    --arg syslog_tls "$SYSLOG_TLS" \
    --arg tls_ca_cert "$TLS_CA_CERT" \
    --arg tls_permitted_peer "$TLS_PERMITTED_PEER" \
    --arg networking_poe_ssl_cert_pem "$NETWORKING_POE_SSL_CERT_PEM" \
    --arg networking_poe_ssl_cert_private_key_pem "$NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM" \
    --arg routing_custom_ca_certificates "$ROUTING_CUSTOM_CA_CERTIFICATES" \
    --arg routing_disable_http "$ROUTING_DISABLE_HTTP" \
    --arg routing_minimum_tls_version "$ROUTING_MINIMUM_TLS_VERSION" \
    --arg routing_tls_termination "$ROUTING_TLS_TERMINATION" \
    --arg gorouter_ssl_ciphers "$GOROUTER_SSL_CIPHERS" \
    --arg haproxy_ssl_ciphers "$HAPROXY_SSL_CIPHERS" \
    --arg haproxy_max_buffer_size "$HAPROXY_MAX_BUFFER_SIZE" \
    --arg haproxy_forward_tls "$HAPROXY_FORWARD_TLS" \
    --arg haproxy_forward_tls_backend_ca "$HAPROXY_FORWARD_TLS_BACKEND_CA" \
    --arg tcp_routing "$TCP_ROUTING" \
    --arg reservable_ports "$TCP_RESERVABLE_PORTS" \
    --arg router_forward_client_cert "$ROUTER_FORWARD_CLIENT_CERT" \
    --arg router_backend_max_conn "$ROUTER_BACKEND_MAX_CONN" \
    --arg route_services "$ROUTE_SERVICES" \
    --arg ignore_ssl_cert_verification "$IGNORE_SSL_CERT_VERIFICATION" \
    --arg container_networking_network_cidr "$CONTAINER_NETWORKING_NETWORK_CIDR" \
    --arg container_networking_vtep_port "$CONTAINER_NETWORKING_VTEP_PORT" \
    --arg container_networking_log_traffic "$CONTAINER_NETWORKING_LOG_TRAFFIC" \
    --arg iptables_denied_logs_per_sec "$IPTABLES_DENIED_LOGS_PER_SEC" \
    --arg iptables_accepted_udp_logs_per_sec "$IPTABLES_ACCEPTED_UDP_LOGS_PER_SEC" \
    --arg networking_point_of_entry "$NETWORKING_POINT_OF_ENTRY" \
    --arg container_networking "$CONTAINER_NETWORKING" \
    --argjson cf_networking_enable_space_developer_self_service "$CF_NETWORKING_ENABLE_SPACE_DEVELOPER_SELF_SERVICE" \
    --arg container_networking_interface_plugin "$CONTAINER_NETWORKING_INTERFACE_PLUGIN" \
    --arg security_acknowledgement "$SECURITY_ACKNOWLEDGEMENT" \
    --arg cf_dial_timeout_in_seconds "$CF_DIAL_TIMEOUT_IN_SECONDS" \
    --arg smoke_tests "$SMOKE_TESTS" \
    --arg smoke_tests_org_name "$SMOKE_TESTS_ORG_NAME" \
    --arg smoke_tests_space_name "$SMOKE_TESTS_SPACE_NAME" \
    --arg smoke_tests_apps_domain "$SMOKE_TESTS_APPS_DOMAIN" \
    --arg smtp_from "$SMTP_FROM" \
    --arg smtp_address "$SMTP_ADDRESS" \
    --arg smtp_port "$SMTP_PORT" \
    --arg smtp_identity "$SMTP_IDENTITY" \
    --arg smtp_password "$SMTP_PASSWORD" \
    --arg smtp_enable_starttls_auto "$SMTP_ENABLE_STARTTLS_AUTO" \
    --arg smtp_auth_mechanism "$SMTP_AUTH_MECHANISM" \
    --arg smtp_crammd5_secret "$SMTP_CRAMMD5_SECRET" \
    --arg system_blobstore "$SYSTEM_BLOBSTORE" \
    --arg s3_endpoint "$S3_ENDPOINT" \
    --arg s3_buildpacks_bucket "$S3_BUILDPACKS_BUCKET" \
    --arg s3_droplets_bucket "$S3_DROPLETS_BUCKET" \
    --arg s3_packages_bucket "$S3_PACKAGES_BUCKET" \
    --arg s3_resources_bucket "$S3_RESOURCES_BUCKET" \
    --arg s3_access_key "$S3_ACCESS_KEY" \
    --arg s3_secret_key "$S3_SECRET_KEY" \
    --arg s3_signature_version "$S3_SIGNATURE_VERSION" \
    --arg s3_region "$S3_REGION" \
    --arg s3_encryption "$S3_ENCRYPTION" \
    --arg gcs_buildpacks_bucket "$GCS_BUILDPACKS_BUCKET" \
    --arg gcs_buildpacks_bucket "$GCS_BUILDPACKS_BUCKET" \
    --arg gcs_packages_bucket "$GCS_PACKAGES_BUCKET" \
    --arg gcs_resources_bucket "$GCS_RESOURCES_BUCKET" \
    --arg gcs_access_key "$GCS_ACCESS_KEY" \
    --arg gcs_secret_key "$GCS_SECRET_KEY" \
    --arg azure_buildpacks_container "$AZURE_BUILDPACKS_CONTAINER" \
    --arg azure_droplets_container "$AZURE_DROPLETS_CONTAINER" \
    --arg azure_packages_container "$AZURE_PACKAGES_CONTAINER" \
    --arg azure_resources_container "$AZURE_RESOURCES_CONTAINER" \
    --arg azure_account_name "$AZURE_ACCOUNT_NAME" \
    --arg azure_access_key "$AZURE_ACCESS_KEY" \
    --arg system_database "$SYSTEM_DATABASE" \
    --arg external_mysql_host "$EXTERNAL_MYSQL_HOST" \
    --arg external_mysql_port "$EXTERNAL_MYSQL_PORT" \
    --arg external_mysql_account_username "$EXTERNAL_MYSQL_ACCOUNT_USERNAME" \
    --arg external_mysql_account_password "$EXTERNAL_MYSQL_ACCOUNT_PASSWORD" \
    --arg external_mysql_app_usage_service_username "$EXTERNAL_MYSQL_APP_USAGE_SERVICE_USERNAME" \
    --arg external_mysql_app_usage_service_password "$EXTERNAL_MYSQL_APP_USAGE_SERVICE_PASSWORD" \
    --arg external_mysql_autoscale_username "$EXTERNAL_MYSQL_AUTOSCALE_USERNAME" \
    --arg external_mysql_autoscale_password "$EXTERNAL_MYSQL_AUTOSCALE_PASSWORD" \
    --arg external_mysql_ccdb_username "$EXTERNAL_MYSQL_CCDB_USERNAME" \
    --arg external_mysql_ccdb_password "$EXTERNAL_MYSQL_CCDB_PASSWORD" \
    --arg external_mysql_diego_username "$EXTERNAL_MYSQL_DIEGO_USERNAME" \
    --arg external_mysql_diego_password "$EXTERNAL_MYSQL_DIEGO_PASSWORD" \
    --arg external_mysql_locket_username "$EXTERNAL_MYSQL_LOCKET_USERNAME" \
    --arg external_mysql_locket_password "$EXTERNAL_MYSQL_LOCKET_PASSWORD" \
    --arg external_mysql_networkpolicyserver_username "$EXTERNAL_MYSQL_NETWORKPOLICYSERVER_USERNAME" \
    --arg external_mysql_networkpolicyserver_password "$EXTERNAL_MYSQL_NETWORKPOLICYSERVER_PASSWORD" \
    --arg external_mysql_nfsvolume_username "$EXTERNAL_MYSQL_NFSVOLUME_USERNAME" \
    --arg external_mysql_nfsvolume_password "$EXTERNAL_MYSQL_NFSVOLUME_PASSWORD" \
    --arg external_mysql_notifications_username "$EXTERNAL_MYSQL_NOTIFICATIONS_USERNAME" \
    --arg external_mysql_notifications_password "$EXTERNAL_MYSQL_NOTIFICATIONS_PASSWORD" \
    --arg external_mysql_routing_username "$EXTERNAL_MYSQL_ROUTING_USERNAME" \
    --arg external_mysql_routing_password "$EXTERNAL_MYSQL_ROUTING_PASSWORD" \
    --arg external_mysql_silk_username "$EXTERNAL_MYSQL_SILK_USERNAME" \
    --arg external_mysql_silk_password "$EXTERNAL_MYSQL_SILK_PASSWORD" \
    --arg mysql_backups "$MYSQL_BACKUPS" \
    --arg mysql_backups_s3_endpoint_url "$MYSQL_BACKUPS_S3_ENDPOINT_URL" \
    --arg mysql_backups_s3_bucket_name "$MYSQL_BACKUPS_S3_BUCKET_NAME" \
    --arg mysql_backups_s3_bucket_path "$MYSQL_BACKUPS_S3_BUCKET_PATH" \
    --arg mysql_backups_s3_access_key_id "$MYSQL_BACKUPS_S3_ACCESS_KEY_ID" \
    --arg mysql_backups_s3_secret_access_key "$MYSQL_BACKUPS_S3_SECRET_ACCESS_KEY" \
    --arg mysql_backups_s3_cron_schedule "$MYSQL_BACKUPS_S3_CRON_SCHEDULE" \
    --arg mysql_backups_s3_backup_all_masters "$MYSQL_BACKUPS_S3_BACKUP_ALL_MASTERS" \
    --arg mysql_backups_s3_region "$MYSQL_BACKUPS_S3_REGION" \
    --arg mysql_backups_gcs_service_account_json "$MYSQL_BACKUPS_GCS_SERVICE_ACCOUNT_JSON" \
    --arg mysql_backups_gcs_project_id "$MYSQL_BACKUPS_GCS_PROJECT_ID" \
    --arg mysql_backups_gcs_bucket_name "$MYSQL_BACKUPS_GCS_BUCKET_NAME" \
    --arg mysql_backups_gcs_cron_schedule "$MYSQL_BACKUPS_GCS_CRON_SCHEDULE" \
    --arg mysql_backups_gcs_backup_all_masters "$MYSQL_BACKUPS_GCS_BACKUP_ALL_MASTERS" \
    --arg mysql_backups_azure_storage_account "$MYSQL_BACKUPS_AZURE_STORAGE_ACCOUNT" \
    --arg mysql_backups_azure_storage_access_key "$MYSQL_BACKUPS_AZURE_STORAGE_ACCESS_KEY" \
    --arg mysql_backups_azure_container "$MYSQL_BACKUPS_AZURE_CONTAINER" \
    --arg mysql_backups_azure_path "$MYSQL_BACKUPS_AZURE_PATH" \
    --arg mysql_backups_azure_cron_schedule "$MYSQL_BACKUPS_AZURE_CRON_SCHEDULE" \
    --arg mysql_backups_azure_backup_all_masters "$MYSQL_BACKUPS_AZURE_BACKUP_ALL_MASTERS" \
    --arg mysql_backups_scp_server "$MYSQL_BACKUPS_SCP_SERVER" \
    --arg mysql_backups_scp_port "$MYSQL_BACKUPS_SCP_PORT" \
    --arg mysql_backups_scp_user "$MYSQL_BACKUPS_SCP_USER" \
    --arg mysql_backups_scp_key "$MYSQL_BACKUPS_SCP_KEY" \
    --arg mysql_backups_scp_destination "$MYSQL_BACKUPS_SCP_DESTINATION" \
    --arg mysql_backups_scp_cron_schedule "$MYSQL_BACKUPS_SCP_CRON_SCHEDULE" \
    --arg mysql_backups_scp_backup_all_masters "$MYSQL_BACKUPS_SCP_BACKUP_ALL_MASTERS" \
    --arg mysql_activity_logging "$MYSQL_ACTIVITY_LOGGING" \
    --arg mysql_activity_logging_audit_logging_events "$MYSQL_ACTIVITY_LOGGING_AUDIT_LOGGING_EVENTS" \
    --arg uaa_auth "$UAA_AUTH" \
    --arg password_min_length "$PASSWORD_MIN_LENGTH" \
    --arg password_min_uppercase "$PASSWORD_MIN_UPPERCASE" \
    --arg password_min_lowercase "$PASSWORD_MIN_LOWERCASE" \
    --arg password_min_numeric "$PASSWORD_MIN_NUMERIC" \
    --arg password_min_special "$PASSWORD_MIN_SPECIAL" \
    --arg password_expires_after_months "$PASSWORD_EXPIRES_AFTER_MONTHS" \
    --arg password_max_retry "$PASSWORD_MAX_RETRY" \
    --arg saml_sso_name "$SAML_SSO_NAME" \
    --arg saml_display_name "$SAML_DISPLAY_NAME" \
    --arg saml_sso_url "$SAML_SSO_URL" \
    --arg saml_name_id_format "$SAML_NAME_ID_FORMAT" \
    --arg saml_sso_xml "$SAML_SSO_XML" \
    --arg saml_sign_auth_requests "$SAML_SIGN_AUTH_REQUESTS" \
    --arg saml_require_signed_assertions "$SAML_REQUIRE_SIGNED_ASSERTIONS" \
    --arg saml_email_domains "$SAML_EMAIL_DOMAINS" \
    --arg saml_first_name_attribute "$SAML_FIRST_NAME_ATTRIBUTE" \
    --arg saml_last_name_attribute "$SAML_LAST_NAME_ATTRIBUTE" \
    --arg saml_email_attribute "$SAML_EMAIL_ATTRIBUTE" \
    --arg saml_external_groups_attribute "$SAML_EXTERNAL_GROUPS_ATTRIBUTE" \
    --arg saml_signature_algorithm "$SAML_SIGNATURE_ALGORITHM" \
    --arg ldap_url "$LDAP_URL" \
    --arg ldap_identity "$LDAP_IDENTITY" \
    --arg ldap_password "$LDAP_PASSWORD" \
    --arg ldap_search_base "$LDAP_SEARCH_BASE" \
    --arg ldap_search_filter "$LDAP_SEARCH_FILTER" \
    --arg ldap_group_search_base "$LDAP_GROUP_SEARCH_BASE" \
    --arg ldap_group_search_filter "$LDAP_GROUP_SEARCH_FILTER" \
    --arg ldap_server_ssl_cert "$LDAP_SERVER_SSL_CERT" \
    --arg ldap_server_ssl_cert_alias "$LDAP_SERVER_SSL_CERT_ALIAS" \
    --arg ldap_mail_attribute_name "$LDAP_MAIL_ATTRIBUTE_NAME" \
    --arg ldap_email_domains "$LDAP_EMAIL_DOMAINS" \
    --arg ldap_first_name_attribute "$LDAP_FIRST_NAME_ATTRIBUTE" \
    --arg ldap_last_name_attribute "$LDAP_LAST_NAME_ATTRIBUTE" \
    --arg ldap_ldap_referrals "$LDAP_LDAP_REFERRALS" \
    --arg uaa_database "$UAA_DATABASE" \
    --arg uaa_database_host "$UAA_DATABASE_HOST" \
    --arg uaa_database_port "$UAA_DATABASE_PORT" \
    --arg uaa_database_username "$UAA_DATABASE_USERNAME" \
    --arg uaa_database_password "$UAA_DATABASE_PASSWORD" \
    --arg blobstore_internal_access_rules "$BLOBSTORE_INTERNAL_ACCESS_RULES" \
    --arg mysql_proxy_static_ips "$MYSQL_PROXY_STATIC_IPS" \
    --arg mysql_proxy_service_hostname "$MYSQL_PROXY_SERVICE_HOSTNAME" \
    --arg mysql_proxy_startup_delay "$MYSQL_PROXY_STARTUP_DELAY" \
    --arg mysql_proxy_shutdown_delay "$MYSQL_PROXY_SHUTDOWN_DELAY" \
    --arg mysql_cli_history "$MYSQL_CLI_HISTORY" \
    --argjson mysql_cluster_probe_timeout "$MYSQL_CLUSTER_PROBE_TIMEOUT" \
    --argjson prevent_node_auto_rejoin "$PREVENT_NODE_AUTO_REJOIN" \
    --arg remote_admin_access "$REMOTE_ADMIN_ACCESS" \
    --arg uaa_private_key_pem "$UAA_PRIVATE_KEY_PEM" \
    --arg uaa_cert_pem "$UAA_CERT_PEM" \
    --arg uaa_private_key_passphrase "$UAA_PRIVATE_KEY_PASSPHRASE" \
    --arg apps_manager_access_token_lifetime "$APPS_MANAGER_ACCESS_TOKEN_LIFETIME" \
    --arg apps_manager_refresh_token_lifetime "$APPS_MANAGER_REFRESH_TOKEN_LIFETIME" \
    --arg cf_cli_access_token_lifetime "$CF_CLI_ACCESS_TOKEN_LIFETIME" \
    --arg cf_cli_refresh_token_lifetime "$CF_CLI_REFRESH_TOKEN_LIFETIME" \
    --arg customize_username_label "$CUSTOMIZE_USERNAME_LABEL" \
    --arg customize_password_label "$CUSTOMIZE_PASSWORD_LABEL" \
    --arg proxy_ips_regex "$PROXY_IPS_REGEX" \
    --arg issuer_uri "$ISSUER_URI" \
    --arg cloud_controller_encrypt_key "$CLOUD_CONTROLLER_ENCRYPT_KEY" \
    --arg max_file_size "$MAX_FILE_SIZE" \
    --arg default_app_memory "$DEFAULT_APP_MEMORY" \
    --arg max_disk_quota_app "$MAX_DISK_QUOTA_APP" \
    --arg default_disk_quota_app "$DEFAULT_DISK_QUOTA_APP" \
    --arg enable_custom_buildpacks "$ENABLE_CUSTOM_BUILDPACKS" \
    --arg system_domain "$SYSTEM_DOMAIN" \
    --arg apps_domain "$APPS_DOMAIN" \
    --arg default_quota_memory_limit_mb "$DEFAULT_QUOTA_MEMORY_LIMIT_MB" \
    --arg default_quota_max_number_services "$DEFAULT_QUOTA_MAX_NUMBER_SERVICES" \
    --arg staging_timeout_in_seconds "$STAGING_TIMEOUT_IN_SECONDS" \
    --arg allow_app_ssh_access "$ALLOW_APP_SSH_ACCESS" \
    --arg default_app_ssh_access "$DEFAULT_APP_SSH_ACCESS" \
    --arg security_event_logging_enabled "$SECURITY_EVENT_LOGGING_ENABLED" \
    --arg ha_proxy_static_ips "$HA_PROXY_STATIC_IPS" \
    --arg skip_cert_verify "$SKIP_CERT_VERIFY" \
    --arg protected_domains "$PROTECTED_DOMAINS" \
    --arg trusted_domain_cidrs "$TRUSTED_DOMAIN_CIDRS" \
    --arg router_static_ips "$ROUTER_STATIC_IPS" \
    --arg disable_insecure_cookies "$DISABLE_INSECURE_COOKIES" \
    --argjson request_timeout_in_seconds "$REQUEST_TIMEOUT_IN_SECONDS" \
    --argjson frontend_idle_timeout "$FRONTEND_IDLE_TIMEOUT" \
    --argjson drain_wait "$DRAIN_WAIT" \
    --argjson lb_healthy_threshold "$LB_HEALTHY_THRESHOLD" \
    --argjson enable_zipkin "$ENABLE_ZIPKIN" \
    --argjson max_idle_connections "$MAX_IDLE_CONNECTIONS" \
    --arg extra_headers_to_log "$EXTRA_HEADERS_TO_LOG" \
    --arg enable_isolated_routing "$ENABLE_ISOLATED_ROUTING" \
    --argjson mysql_monitor_poll_frequency "$MYSQL_MONITOR_POLL_FREQUENCY" \
    --argjson mysql_monitor_write_read_delay "$MYSQL_MONITOR_WRITE_READ_DELAY" \
    --arg mysql_monitor_recipient_email "$MYSQL_MONITOR_RECIPIENT_EMAIL" \
    --arg diego_brain_static_ips "$DIEGO_BRAIN_STATIC_IPS" \
    --argjson starting_container_count_maximum "$STARTING_CONTAINER_COUNT_MAXIMUM" \
    --arg executor_disk_capacity "$EXECUTOR_DISK_CAPACITY" \
    --arg executor_memory_capacity "$EXECUTOR_MEMORY_CAPACITY" \
    --arg insecure_docker_registry_list "$INSECURE_DOCKER_REGISTRY_LIST" \
    --argjson garden_network_mtu "$GARDEN_NETWORK_MTU" \
    --argjson message_drain_buffer_size "$MESSAGE_DRAIN_BUFFER_SIZE" \
    --arg tcp_router_static_ips "$TCP_ROUTER_STATIC_IPS" \
    --arg company_name "$COMPANY_NAME" \
    --arg accent_color "$ACCENT_COLOR" \
    --arg global_wrapper_bg_color "$GLOBAL_WRAPPER_BG_COLOR" \
    --arg global_wrapper_text_color "$GLOBAL_WRAPPER_TEXT_COLOR" \
    --arg global_wrapper_header_content "$GLOBAL_WRAPPER_HEADER_CONTENT" \
    --arg global_wrapper_footer_content "$GLOBAL_WRAPPER_FOOTER_CONTENT" \
    --arg logo "$LOGO" \
    --arg square_logo "$SQUARE_LOGO" \
    --arg footer_text "$FOOTER_TEXT" \
    --arg nav_links_name_1 "$NAV_LINKS_NAME_1" \
    --arg nav_links_href_1 "$NAV_LINKS_HREF_1" \
    --arg nav_links_name_2 "$NAV_LINKS_NAME_2" \
    --arg nav_links_href_2 "$NAV_LINKS_HREF_2" \
    --arg nav_links_name_3 "$NAV_LINKS_NAME_3" \
    --arg nav_links_href_3 "$NAV_LINKS_HREF_3" \
    --arg apps_manager_product_name "$APPS_MANAGER_PRODUCT_NAME" \
    --arg marketplace_name "$MARKETPLACE_NAME" \
    --arg enable_invitations "$ENABLE_INVITATIONS" \
    --arg display_plan_prices "$DISPLAY_PLAN_PRICES" \
    --arg currency_lookup "$CURRENCY_LOOKUP" \
    '
    . +
    {
      ".properties.cc_api_rate_limit":{"value":$cc_api_rate_limit}
    }
    +
    if $cc_api_rate_limit == "enable" then
    {
      ".properties.cc_api_rate_limit.enable.general_limit":{"value":$general_limit},
      ".properties.cc_api_rate_limit.enable.unauthenticated_limit":{"value":$unauthenticated_limit}
    }
    else .
    end
    +
    {
      ".properties.credhub_key_encryption_password": {
        "value": {
          "secret": $credhub_key_encryption_password
        }
      },
      ".properties.secure_service_instance_credentials": {
        "value": $secure_service_instance_credentials
      }
    }
    +
    if $credhub_database == "external" then
    {
      ".properties.credhub_database": {
        "value": "$credhub_database"
      },
      ".properties.credhub_database.external.host": {
        "value": $credhub_database_external_host
      },
      ".properties.credhub_database.external.port": {
        "value": $credhub_database_external_port
      },
      ".properties.credhub_database.external.username": {
        "value": $credhub_database_external_username
      },
      ".properties.credhub_database.external.password": {
        "value": {
          "secret": $credhub_database_external_password
        }
      },
      ".properties.credhub_database.external.tls_ca": {
        "value": $credhub_database_external_tls_ca
      }
    }
    else .
    end
    +
    {
      ".properties.nfs_volume_driver":{"value":$nfs_volume_driver}
    }
    +
    if $nfs_volume_driver == "enable" then
    {
      ".properties.nfs_volume_driver.enable.ldap_service_account_user":{"value":$ldap_service_account_user},
      ".properties.nfs_volume_driver.enable.ldap_service_account_password":{"value":{"secret":$ldap_service_account_password}},
      ".properties.nfs_volume_driver.enable.ldap_server_host":{"value":$ldap_server_host},
      ".properties.nfs_volume_driver.enable.ldap_server_port":{"value":$ldap_server_port},
      ".properties.nfs_volume_driver.enable.ldap_user_fqdn":{"value":$ldap_user_fqdn}
    }
    else .
    end
    +
    {
      ".properties.garden_disk_cleanup":{"value":$garden_disk_cleanup},
      ".properties.enable_grootfs":{"value":$enable_grootfs},
      ".properties.logger_endpoint_port":{"value":$logger_endpoint_port},
      ".properties.syslog_host":{"value":$syslog_host},
      ".properties.syslog_port":{"value":$syslog_port},
      ".properties.syslog_protocol":{"value":$syslog_protocol},
      ".properties.syslog_tls":{"value":$syslog_tls}
    }
    +
    if $syslog_tls == "enabled" then
    {
      ".properties.syslog_tls.enabled.tls_ca_cert":{"value":$tls_ca_cert},
      ".properties.syslog_tls.enabled.tls_permitted_peer":{"value":$tls_permitted_peer}
    }
    else .
    end
    +
    {
      ".properties.networking_poe_ssl_cert":{
        "value": [
          {
            "cert_pem":$networking_poe_ssl_cert_pem,
            "private_key_pem":$networking_poe_ssl_cert_private_key_pem
          }
        ]
      },
      ".properties.routing_custom_ca_certificates":{"value":$routing_custom_ca_certificates},
      ".properties.routing_disable_http":{"value":$routing_disable_http},
      ".properties.routing_minimum_tls_version":{"value":$routing_minimum_tls_version},
      ".properties.routing_tls_termination":{"value":$routing_tls_termination},
      ".properties.gorouter_ssl_ciphers":{"value":$gorouter_ssl_ciphers},
      ".properties.haproxy_ssl_ciphers":{"value":$haproxy_ssl_ciphers},
      ".properties.haproxy_max_buffer_size":{"value":$haproxy_max_buffer_size},
      ".properties.haproxy_forward_tls":{"value":$haproxy_forward_tls}
    }
    +
    if $haproxy_forward_tls == "enable" then
    {
      ".properties.haproxy_forward_tls.enable.backend_ca":{"value":$haproxy_forward_tls_backend_ca}
    }
    else .
    end
    +
    {
      ".properties.tcp_routing":{"value":$tcp_routing}
    }
    +
    if $tcp_routing == "enable" then
    {
      ".properties.tcp_routing.enable.reservable_ports":{"value":$reservable_ports}
    }
    else .
    end
    +
    {
      ".properties.router_forward_client_cert":{"value":$router_forward_client_cert},
      ".properties.router_backend_max_conn":{"value":$router_backend_max_conn},
      ".properties.route_services":{"value":$route_services}
    }
    +
    if $route_services == "enable" then
    {
      ".properties.route_services.enable.ignore_ssl_cert_verification":{"value":$ignore_ssl_cert_verification}
    }
    else .
    end
    +
    {
      ".properties.container_networking_network_cidr":{"value":$container_networking_network_cidr},
      ".properties.container_networking_vtep_port":{"value":$container_networking_vtep_port},
      ".properties.container_networking_log_traffic":{"value":$container_networking_log_traffic}
    }
    +
    if $container_networking_log_traffic == "enable" then
    {
      ".properties.container_networking_log_traffic.enable.iptables_denied_logs_per_sec":{"value":$iptables_denied_logs_per_sec},
      ".properties.container_networking_log_traffic.enable.iptables_accepted_udp_logs_per_sec":{"value":$iptables_accepted_udp_logs_per_sec}
    }
    else .
    end
    +
    {
      ".properties.networking_point_of_entry":{"value":$networking_point_of_entry},
      ".properties.container_networking":{"value":$container_networking},
      ".properties.container_networking_interface_plugin":{"value":$container_networking_interface_plugin},
      ".properties.cf_networking_enable_space_developer_self_service":{"value":$cf_networking_enable_space_developer_self_service},
      ".properties.security_acknowledgement":{"value":$security_acknowledgement},
      ".properties.cf_dial_timeout_in_seconds":{"value":$cf_dial_timeout_in_seconds},
      ".properties.smoke_tests":{"value":$smoke_tests}
    }
    +
    if $smoke_tests == "specified" then
    {
      ".properties.smoke_tests.specified.org_name":{"value":$smoke_tests_org_name},
      ".properties.smoke_tests.specified.space_name":{"value":$smoke_tests_space_name},
      ".properties.smoke_tests.specified.apps_domain":{"value":$smoke_tests_apps_domain}
    }
    else .
    end
    +
    {
      ".properties.smtp_from":{"value":$smtp_from},
      ".properties.smtp_address":{"value":$smtp_address},
      ".properties.smtp_port":{"value":$smtp_port},
      ".properties.smtp_credentials":{"value":{"identity":$smtp_identity,"password":$smtp_password}},
      ".properties.smtp_enable_starttls_auto":{"value":$smtp_enable_starttls_auto},
      ".properties.smtp_auth_mechanism":{"value":$smtp_auth_mechanism},
      ".properties.smtp_crammd5_secret":{"value":$smtp_crammd5_secret},
      ".properties.system_blobstore":{"value":$system_blobstore}
    }
    +
    if $system_blobstore == "s3" then
    {
      ".properties.system_blobstore":{"value":"external"},
      ".properties.system_blobstore.external.endpoint":{"value":$s3_endpoint},
      ".properties.system_blobstore.external.buildpacks_bucket":{"value":$s3_buildpacks_bucket},
      ".properties.system_blobstore.external.droplets_bucket":{"value":$s3_droplets_bucket},
      ".properties.system_blobstore.external.packages_bucket":{"value":$s3_packages_bucket},
      ".properties.system_blobstore.external.resources_bucket":{"value":$s3_resources_bucket},
      ".properties.system_blobstore.external.access_key":{"value":$s3_access_key},
      ".properties.system_blobstore.external.secret_key":{"value":{"secret":$s3_secret_key}},
      ".properties.system_blobstore.external.signature_version":{"value":$s3_signature_version},
      ".properties.system_blobstore.external.region":{"value":$s3_region},
      ".properties.system_blobstore.external.encryption":{"value":$s3_encryption}
    }
    elif $system_blobstore == "gcs" then
    {
      ".properties.system_blobstore":{"value":"external_gcs"},
      ".properties.system_blobstore.external_gcs.buildpacks_bucket":{"value":$gcs_buildpacks_bucket},
      ".properties.system_blobstore.external_gcs.buildpacks_bucket":{"value":$gcs_buildpacks_bucket},
      ".properties.system_blobstore.external_gcs.packages_bucket":{"value":$gcs_packages_bucket},
      ".properties.system_blobstore.external_gcs.resources_bucket":{"value":$gcs_resources_bucket},
      ".properties.system_blobstore.external_gcs.access_key":{"value":$gcs_access_key},
      ".properties.system_blobstore.external_gcs.secret_key":{"value":{"secret":$gcs_secret_key}}
    }
    elif $system_blobstore == "azure" then
    {
      ".properties.system_blobstore":{"value":"external_azure"},
      ".properties.system_blobstore.external_azure.buildpacks_container":{"value":$azure_buildpacks_container},
      ".properties.system_blobstore.external_azure.droplets_container":{"value":$azure_droplets_container},
      ".properties.system_blobstore.external_azure.packages_container":{"value":$azure_packages_container},
      ".properties.system_blobstore.external_azure.resources_container":{"value":$azure_resources_container},
      ".properties.system_blobstore.external_azure.account_name":{"value":$azure_account_name},
      ".properties.system_blobstore.external_azure.access_key":{"value":{"secret":$azure_access_key}}
    }
    else .
    end
    +
    {
      ".properties.system_database":{"value":$system_database}
    }
    +
    if $system_database == "external" then
    {
      ".properties.system_database.external.host":{"value":$external_mysql_host},
      ".properties.system_database.external.port":{"value":$external_mysql_port},
      ".properties.system_database.external.account_username":{"value":$external_mysql_account_username},
      ".properties.system_database.external.account_password":{"value":{"secret":$external_mysql_account_password}},
      ".properties.system_database.external.app_usage_service_username":{"value":$external_mysql_app_usage_service_username},
      ".properties.system_database.external.app_usage_service_password":{"value":{"secret":$external_mysql_app_usage_service_password}},
      ".properties.system_database.external.autoscale_username":{"value":$external_mysql_autoscale_username},
      ".properties.system_database.external.autoscale_password":{"value":{"secret":$external_mysql_autoscale_password}},
      ".properties.system_database.external.ccdb_username":{"value":$external_mysql_ccdb_username},
      ".properties.system_database.external.ccdb_password":{"value":{"secret":$external_mysql_ccdb_password}},
      ".properties.system_database.external.diego_username":{"value":$external_mysql_diego_username},
      ".properties.system_database.external.diego_password":{"value":{"secret":$external_mysql_diego_password}},
      ".properties.system_database.external.locket_username":{"value":$external_mysql_locket_username},
      ".properties.system_database.external.locket_password":{"value":{"secret":$external_mysql_locket_password}},
      ".properties.system_database.external.networkpolicyserver_username":{"value":$external_mysql_networkpolicyserver_username},
      ".properties.system_database.external.networkpolicyserver_password":{"value":{"secret":$external_mysql_networkpolicyserver_password}},
      ".properties.system_database.external.nfsvolume_username":{"value":$external_mysql_nfsvolume_username},
      ".properties.system_database.external.nfsvolume_password":{"value":{"secret":$external_mysql_nfsvolume_password}},
      ".properties.system_database.external.notifications_username":{"value":$external_mysql_notifications_username},
      ".properties.system_database.external.notifications_password":{"value":{"secret":$external_mysql_notifications_password}},
      ".properties.system_database.external.routing_username":{"value":$external_mysql_routing_username},
      ".properties.system_database.external.routing_password":{"value":{"secret":$external_mysql_routing_password}},
      ".properties.system_database.external.silk_username":{"value":$external_mysql_silk_username},
      ".properties.system_database.external.silk_password":{"value":{"secret":$external_mysql_silk_password}}
    }
    else .
    end
    +
    {
      ".properties.mysql_backups":{"value":$mysql_backups}
    }
    +
    if $mysql_backups == "s3" then
    {
      ".properties.mysql_backups.s3.endpoint_url":{"value":$mysql_backups_s3_endpoint_url},
      ".properties.mysql_backups.s3.bucket_name":{"value":$mysql_backups_s3_bucket_name},
      ".properties.mysql_backups.s3.bucket_path":{"value":$mysql_backups_s3_bucket_path},
      ".properties.mysql_backups.s3.access_key_id":{"value":$mysql_backups_s3_access_key_id},
      ".properties.mysql_backups.s3.secret_access_key":{"value":{"secret":$mysql_backups_s3_secret_access_key}},
      ".properties.mysql_backups.s3.cron_schedule":{"value":$mysql_backups_s3_cron_schedule},
      ".properties.mysql_backups.s3.backup_all_masters":{"value":$mysql_backups_s3_backup_all_masters},
      ".properties.mysql_backups.s3.region":{"value":$mysql_backups_s3_region}
    }
    elif $mysql_backups == "gcs" then
    {
      ".properties.mysql_backups.gcs.service_account_json":{"value":{"secret":$mysql_backups_gcs_service_account_json}},
      ".properties.mysql_backups.gcs.project_id":{"value":$mysql_backups_gcs_project_id},
      ".properties.mysql_backups.gcs.bucket_name":{"value":$mysql_backups_gcs_bucket_name},
      ".properties.mysql_backups.gcs.cron_schedule":{"value":$mysql_backups_gcs_cron_schedule},
      ".properties.mysql_backups.gcs.backup_all_masters":{"value":$mysql_backups_gcs_backup_all_masters}
    }
    elif $mysql_backups == "azure" then
    {
      ".properties.mysql_backups.azure.storage_account":{"value":$mysql_backups_azure_storage_account},
      ".properties.mysql_backups.azure.storage_access_key":{"value":{"secret":$mysql_backups_azure_storage_access_key}},
      ".properties.mysql_backups.azure.container":{"value":$mysql_backups_azure_container},
      ".properties.mysql_backups.azure.path":{"value":$mysql_backups_azure_path},
      ".properties.mysql_backups.azure.cron_schedule":{"value":$mysql_backups_azure_cron_schedule},
      ".properties.mysql_backups.azure.backup_all_masters":{"value":$mysql_backups_azure_backup_all_masters}
    }
    elif $mysql_backups == "scp" then
    {
      ".properties.mysql_backups.scp.server":{"value":$mysql_backups_scp_server},
      ".properties.mysql_backups.scp.port":{"value":$mysql_backups_scp_port},
      ".properties.mysql_backups.scp.user":{"value":$mysql_backups_scp_user},
      ".properties.mysql_backups.scp.key":{"value":$mysql_backups_scp_key},
      ".properties.mysql_backups.scp.destination":{"value":$mysql_backups_scp_destination},
      ".properties.mysql_backups.scp.cron_schedule":{"value":$mysql_backups_scp_cron_schedule},
      ".properties.mysql_backups.scp.backup_all_masters":{"value":$mysql_backups_scp_backup_all_masters}
    }
    else .
    end
    +
    {
      ".properties.mysql_activity_logging":{"value":$mysql_activity_logging}
    }
    +
    if $mysql_activity_logging == "enable" then
    {
      ".properties.mysql_activity_logging.enable.audit_logging_events":{"value":$mysql_activity_logging_audit_logging_events}
    }
    else .
    end
    +
    {
      ".properties.uaa":{"value":$uaa_auth}
    }
    +
    if $uaa_auth == "internal" then
    {
      ".properties.uaa.internal.password_min_length":{"value":$password_min_length},
      ".properties.uaa.internal.password_min_uppercase":{"value":$password_min_uppercase},
      ".properties.uaa.internal.password_min_lowercase":{"value":$password_min_lowercase},
      ".properties.uaa.internal.password_min_numeric":{"value":$password_min_numeric},
      ".properties.uaa.internal.password_min_special":{"value":$password_min_special},
      ".properties.uaa.internal.password_expires_after_months":{"value":$password_expires_after_months},
      ".properties.uaa.internal.password_max_retry":{"value":$password_max_retry}
    }
    elif $uaa_auth == "saml" then
    {
      ".properties.uaa.saml.sso_name":{"value":$saml_sso_name},
      ".properties.uaa.saml.display_name":{"value":$saml_display_name},
      ".properties.uaa.saml.sso_url":{"value":$saml_sso_url},
      ".properties.uaa.saml.name_id_format":{"value":$saml_name_id_format},
      ".properties.uaa.saml.sso_xml":{"value":$saml_sso_xml},
      ".properties.uaa.saml.sign_auth_requests":{"value":$saml_sign_auth_requests},
      ".properties.uaa.saml.require_signed_assertions":{"value":$saml_require_signed_assertions},
      ".properties.uaa.saml.email_domains":{"value":$saml_email_domains},
      ".properties.uaa.saml.first_name_attribute":{"value":$saml_first_name_attribute},
      ".properties.uaa.saml.last_name_attribute":{"value":$saml_last_name_attribute},
      ".properties.uaa.saml.email_attribute":{"value":$saml_email_attribute},
      ".properties.uaa.saml.external_groups_attribute":{"value":$saml_external_groups_attribute},
      ".properties.saml_signature_algorithm":{"value":$saml_signature_algorithm}
    }
    elif $uaa_auth == "ldap" then
    {
      ".properties.uaa.ldap.url":{"value":$ldap_url},
      ".properties.uaa.ldap.credentials":{"value":{"identity":$ldap_identity,"password":$ldap_password}},
      ".properties.uaa.ldap.search_base":{"value":$ldap_search_base},
      ".properties.uaa.ldap.search_filter":{"value":$ldap_search_filter},
      ".properties.uaa.ldap.group_search_base":{"value":$ldap_group_search_base},
      ".properties.uaa.ldap.group_search_filter":{"value":$ldap_group_search_filter},
      ".properties.uaa.ldap.server_ssl_cert":{"value":$ldap_server_ssl_cert},
      ".properties.uaa.ldap.server_ssl_cert_alias":{"value":$ldap_server_ssl_cert_alias},
      ".properties.uaa.ldap.mail_attribute_name":{"value":$ldap_mail_attribute_name},
      ".properties.uaa.ldap.email_domains":{"value":$ldap_email_domains},
      ".properties.uaa.ldap.first_name_attribute":{"value":$ldap_first_name_attribute},
      ".properties.uaa.ldap.last_name_attribute":{"value":$ldap_last_name_attribute},
      ".properties.uaa.ldap.ldap_referrals":{"value":$ldap_ldap_referrals}
    }
    else .
    end
    +
    {
      ".properties.uaa_database":{"value":$uaa_database}
    }
    +
    if $uaa_database == "external" then
    {
      ".properties.uaa_database.external.host":{"value":$uaa_database_host},
      ".properties.uaa_database.external.port":{"value":$uaa_database_port},
      ".properties.uaa_database.external.uaa_username":{"value":$uaa_database_username},
      ".properties.uaa_database.external.uaa_password":{"value":{"secret":$uaa_database_password}}
    }
    else .
    end
    +
    {
      ".nfs_server.blobstore_internal_access_rules":{"value":$blobstore_internal_access_rules},
      ".mysql_proxy.static_ips":{"value":$mysql_proxy_static_ips},
      ".mysql_proxy.service_hostname":{"value":$mysql_proxy_service_hostname},
      ".mysql_proxy.startup_delay":{"value":$mysql_proxy_startup_delay},
      ".mysql_proxy.shutdown_delay":{"value":$mysql_proxy_shutdown_delay},
      ".mysql.cli_history":{"value":$mysql_cli_history},
      ".mysql.cluster_probe_timeout":{"value":$mysql_cluster_probe_timeout},
      ".mysql.prevent_node_auto_rejoin":{"value":$prevent_node_auto_rejoin},
      ".mysql.remote_admin_access":{"value":$remote_admin_access},
      ".uaa.service_provider_key_credentials":{"value":{"private_key_pem":$uaa_private_key_pem,"cert_pem":$uaa_cert_pem}},
      ".uaa.service_provider_key_password":{"value":{"secret":$uaa_private_key_passphrase}},
      ".uaa.apps_manager_access_token_lifetime":{"value":$apps_manager_access_token_lifetime},
      ".uaa.apps_manager_refresh_token_lifetime":{"value":$apps_manager_refresh_token_lifetime},
      ".uaa.cf_cli_access_token_lifetime":{"value":$cf_cli_access_token_lifetime},
      ".uaa.cf_cli_refresh_token_lifetime":{"value":$cf_cli_refresh_token_lifetime},
      ".uaa.customize_username_label":{"value":$customize_username_label},
      ".uaa.customize_password_label":{"value":$customize_password_label},
      ".uaa.proxy_ips_regex":{"value":$proxy_ips_regex},
      ".uaa.issuer_uri":{"value":$issuer_uri},
      ".cloud_controller.encrypt_key":{"value":{"secret":$cloud_controller_encrypt_key}},
      ".cloud_controller.max_file_size":{"value":$max_file_size},
      ".cloud_controller.default_app_memory":{"value":$default_app_memory},
      ".cloud_controller.max_disk_quota_app":{"value":$max_disk_quota_app},
      ".cloud_controller.default_disk_quota_app":{"value":$default_disk_quota_app},
      ".cloud_controller.enable_custom_buildpacks":{"value":$enable_custom_buildpacks},
      ".cloud_controller.system_domain":{"value":$system_domain},
      ".cloud_controller.apps_domain":{"value":$apps_domain},
      ".cloud_controller.default_quota_memory_limit_mb":{"value":$default_quota_memory_limit_mb},
      ".cloud_controller.default_quota_max_number_services":{"value":$default_quota_max_number_services},
      ".cloud_controller.staging_timeout_in_seconds":{"value":$staging_timeout_in_seconds},
      ".cloud_controller.allow_app_ssh_access":{"value":$allow_app_ssh_access},
      ".cloud_controller.default_app_ssh_access":{"value":$default_app_ssh_access},
      ".cloud_controller.security_event_logging_enabled":{"value":$security_event_logging_enabled},
      ".ha_proxy.static_ips":{"value":$ha_proxy_static_ips},
      ".ha_proxy.skip_cert_verify":{"value":$skip_cert_verify},
      ".ha_proxy.internal_only_domains":{"value":$protected_domains},
      ".ha_proxy.trusted_domain_cidrs":{"value":$trusted_domain_cidrs},
      ".router.static_ips":{"value":$router_static_ips},
      ".router.disable_insecure_cookies":{"value":$disable_insecure_cookies},
      ".router.request_timeout_in_seconds":{"value":$request_timeout_in_seconds},
      ".router.frontend_idle_timeout":{"value":$frontend_idle_timeout},
      ".router.drain_wait":{"value":$drain_wait},
      ".router.lb_healthy_threshold":{"value":$lb_healthy_threshold},
      ".router.enable_zipkin":{"value":$enable_zipkin},
      ".router.max_idle_connections":{"value":$max_idle_connections},
      ".router.extra_headers_to_log":{"value":$extra_headers_to_log},
      ".router.enable_isolated_routing":{"value":$enable_isolated_routing},
      ".mysql_monitor.poll_frequency":{"value":$mysql_monitor_poll_frequency},
      ".mysql_monitor.write_read_delay":{"value":$mysql_monitor_write_read_delay},
      ".mysql_monitor.recipient_email":{"value":$mysql_monitor_recipient_email},
      ".diego_brain.static_ips":{"value":$diego_brain_static_ips},
      ".diego_brain.starting_container_count_maximum":{"value":$starting_container_count_maximum},
      ".diego_cell.executor_disk_capacity":{"value":$executor_disk_capacity},
      ".diego_cell.executor_memory_capacity":{"value":$executor_memory_capacity},
      ".diego_cell.insecure_docker_registry_list":{"value":$insecure_docker_registry_list},
      ".diego_cell.garden_network_mtu":{"value":$garden_network_mtu},
      ".doppler.message_drain_buffer_size":{"value":$message_drain_buffer_size},
      ".tcp_router.static_ips":{"value":$tcp_router_static_ips},
      ".properties.push_apps_manager_company_name":{"value":$company_name},
      ".properties.push_apps_manager_accent_color":{"value":$accent_color},
      ".properties.push_apps_manager_global_wrapper_bg_color":{"value":$global_wrapper_bg_color},
      ".properties.push_apps_manager_global_wrapper_text_color":{"value":$global_wrapper_text_color},
      ".properties.push_apps_manager_global_wrapper_header_content":{"value":$global_wrapper_header_content},
      ".properties.push_apps_manager_global_wrapper_footer_content":{"value":$global_wrapper_footer_content},
      ".properties.push_apps_manager_logo":{"value":$logo},
      ".properties.push_apps_manager_square_logo":{"value":$square_logo},
      ".properties.push_apps_manager_footer_text":{"value":$footer_text}
    }
    +
    if $nav_links_name_1 != "" then
    {
      ".properties.push_apps_manager_nav_links":{
        "value":[
          {
            "name": $nav_links_name_1,
            "href": $nav_links_href_1
          },
          {
            "name": $nav_links_name_2,
            "href": $nav_links_href_2
          },
          {
            "name": $nav_links_name_3,
            "href": $nav_links_href_3
          }]
      }
    }
    else .
    end
    +
    {
      ".properties.push_apps_manager_product_name":{"value":$apps_manager_product_name},
      ".properties.push_apps_manager_marketplace_name":{"value":$marketplace_name},
      ".properties.push_apps_manager_enable_invitations":{"value":$enable_invitations},
      ".properties.push_apps_manager_display_plan_prices":{"value":$display_plan_prices},
      ".properties.push_apps_manager_currency_lookup":{"value":$currency_lookup}
    }
    '
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
  "credhub": {
    "instance_type": {"id": "$CREDHUB_INSTANCE_TYPE"},
    "instances" : $CREDHUB_INSTANCES
  }
}
EOF
)

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_PROPERTIES" -pn "$CF_NETWORK" -pr "$CF_RESOURCES"
