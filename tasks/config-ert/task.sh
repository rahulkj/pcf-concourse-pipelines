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

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

CF_RELEASE=$($OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k -f json available-products)

PRODUCT_NAME=$(echo "$CF_RELEASE" | $JQ_CMD -r --arg deployment_name cf '.[] | select(.name==$deployment_name) | .name')
PRODUCT_VERSION=$(echo "$CF_RELEASE" | $JQ_CMD -r --arg deployment_name cf '.[] | select(.name==$deployment_name) | .version')

$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

if [[ -z "$NETWORKING_POE_SSL_CERT_PEM" ]]; then
DOMAINS=$(cat <<-EOF
  {"domains": ["*.$CLOUD_CONTROLLER_SYSTEM_DOMAIN", "*.$CLOUD_CONTROLLER_APPS_DOMAIN", "*.login.$CLOUD_CONTROLLER_SYSTEM_DOMAIN", "*.uaa.$CLOUD_CONTROLLER_SYSTEM_DOMAIN"] }
EOF
)

SECURITY_DOMAIN=$(cat <<-EOF
  {"domains": ["*.login.$CLOUD_CONTROLLER_SYSTEM_DOMAIN", "*.uaa.$CLOUD_CONTROLLER_SYSTEM_DOMAIN"] }
EOF
)

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "/api/v0/certificates/generate" -x POST -d "$DOMAINS"`

  export NETWORKING_POE_SSL_NAME="GENERATED-CERTS"
  export NETWORKING_POE_SSL_CERT_PEM=`echo $CERTIFICATES | jq --raw-output '.certificate'`
  export NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM=`echo $CERTIFICATES | jq --raw-output '.key'`

  CERTIFICATES=`$OM_CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "/api/v0/certificates/generate" -x POST -d "$SECURITY_DOMAIN"`

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

properties_config=$($JQ_CMD -n \
  --arg cloud_controller_allow_app_ssh_access "${CLOUD_CONTROLLER_ALLOW_APP_SSH_ACCESS:-true}" \
  --arg cloud_controller_apps_domain "${CLOUD_CONTROLLER_APPS_DOMAIN:-""}" \
  --arg cloud_controller_default_app_memory "${CLOUD_CONTROLLER_DEFAULT_APP_MEMORY:-1024}" \
  --arg cloud_controller_default_app_ssh_access "${CLOUD_CONTROLLER_DEFAULT_APP_SSH_ACCESS:-true}" \
  --arg cloud_controller_default_disk_quota_app "${CLOUD_CONTROLLER_DEFAULT_DISK_QUOTA_APP:-1024}" \
  --arg cloud_controller_default_quota_max_number_services "${CLOUD_CONTROLLER_DEFAULT_QUOTA_MAX_NUMBER_SERVICES:-100}" \
  --arg cloud_controller_default_quota_memory_limit_mb "${CLOUD_CONTROLLER_DEFAULT_QUOTA_MEMORY_LIMIT_MB:-10240}" \
  --arg cloud_controller_enable_custom_buildpacks "${CLOUD_CONTROLLER_ENABLE_CUSTOM_BUILDPACKS:-true}" \
  --arg cloud_controller_encrypt_key "${CLOUD_CONTROLLER_ENCRYPT_KEY}" \
  --arg cloud_controller_max_disk_quota_app "${CLOUD_CONTROLLER_MAX_DISK_QUOTA_APP:-2048}" \
  --arg cloud_controller_max_file_size "${CLOUD_CONTROLLER_MAX_FILE_SIZE:-1024}" \
  --arg cloud_controller_security_event_logging_enabled "${CLOUD_CONTROLLER_SECURITY_EVENT_LOGGING_ENABLED:-true}" \
  --arg cloud_controller_staging_timeout_in_seconds "${CLOUD_CONTROLLER_STAGING_TIMEOUT_IN_SECONDS:-900}" \
  --arg cloud_controller_system_domain "${CLOUD_CONTROLLER_SYSTEM_DOMAIN:-""}" \
  --arg diego_brain_starting_container_count_maximum "${DIEGO_BRAIN_STARTING_CONTAINER_COUNT_MAXIMUM:-200}" \
  --arg diego_brain_static_ips "${DIEGO_BRAIN_STATIC_IPS:-""}" \
  --arg diego_cell_executor_disk_capacity "${DIEGO_CELL_EXECUTOR_DISK_CAPACITY:-""}" \
  --arg diego_cell_executor_memory_capacity "${DIEGO_CELL_EXECUTOR_MEMORY_CAPACITY:-""}" \
  --arg diego_cell_insecure_docker_registry_list "${DIEGO_CELL_INSECURE_DOCKER_REGISTRY_LIST:-""}" \
  --arg doppler_message_drain_buffer_size "${DOPPLER_MESSAGE_DRAIN_BUFFER_SIZE:-10000}" \
  --arg ha_proxy_internal_only_domains "${HA_PROXY_INTERNAL_ONLY_DOMAINS:-""}" \
  --arg ha_proxy_skip_cert_verify "${HA_PROXY_SKIP_CERT_VERIFY:-true}" \
  --arg ha_proxy_static_ips "${HA_PROXY_STATIC_IPS:-""}" \
  --arg ha_proxy_trusted_domain_cidrs "${HA_PROXY_TRUSTED_DOMAIN_CIDRS:-""}" \
  --arg mysql_cli_history "${MYSQL_CLI_HISTORY:-true}" \
  --arg mysql_cluster_probe_timeout "${MYSQL_CLUSTER_PROBE_TIMEOUT:-""}" \
  --arg mysql_prevent_node_auto_rejoin "${MYSQL_PREVENT_NODE_AUTO_REJOIN:-false}" \
  --arg mysql_remote_admin_access "${MYSQL_REMOTE_ADMIN_ACCESS:-false}" \
  --arg mysql_monitor_poll_frequency "${MYSQL_MONITOR_POLL_FREQUENCY:-30}" \
  --arg mysql_monitor_recipient_email "${MYSQL_MONITOR_RECIPIENT_EMAIL:-""}" \
  --arg mysql_monitor_write_read_delay "${MYSQL_MONITOR_WRITE_READ_DELAY:-20}" \
  --arg mysql_proxy_service_hostname "${MYSQL_PROXY_SERVICE_HOSTNAME:-""}" \
  --arg mysql_proxy_shutdown_delay "${MYSQL_PROXY_SHUTDOWN_DELAY:-30}" \
  --arg mysql_proxy_startup_delay "${MYSQL_PROXY_STARTUP_DELAY:-0}" \
  --arg mysql_proxy_static_ips "${MYSQL_PROXY_STATIC_IPS:-""}" \
  --arg nfs_server_blobstore_internal_access_rules "${NFS_SERVER_BLOBSTORE_INTERNAL_ACCESS_RULES:-"allow 10.0.0.0/8;,allow 172.16.0.0/12;,allow 192.168.0.0/16;"}" \
  --arg autoscale_api_instance_count "${AUTOSCALE_API_INSTANCE_COUNT:-1}" \
  --arg autoscale_instance_count "${AUTOSCALE_INSTANCE_COUNT:-3}" \
  --arg autoscale_metric_bucket_count "${AUTOSCALE_METRIC_BUCKET_COUNT:-35}" \
  --arg autoscale_scaling_interval_in_seconds "${AUTOSCALE_SCALING_INTERVAL_IN_SECONDS:-35}" \
  --arg cc_api_rate_limit "${CC_API_RATE_LIMIT:-"disable"}" \
  --arg cc_api_rate_limit_enable_general_limit "${CC_API_RATE_LIMIT_ENABLE_GENERAL_LIMIT:-2000}" \
  --arg cc_api_rate_limit_enable_unauthenticated_limit "${CC_API_RATE_LIMIT_ENABLE_UNAUTHENTICATED_LIMIT:-100}" \
  --arg cf_dial_timeout_in_seconds "${CF_DIAL_TIMEOUT_IN_SECONDS:-""}" \
  --arg cf_networking_enable_space_developer_self_service "${CF_NETWORKING_ENABLE_SPACE_DEVELOPER_SELF_SERVICE:-false}" \
  --arg container_networking "${CONTAINER_NETWORKING:-"enable"}" \
  --arg container_networking_interface_plugin "${CONTAINER_NETWORKING_INTERFACE_PLUGIN:-"silk"}" \
  --arg container_networking_interface_plugin_silk_dns_servers "${CONTAINER_NETWORKING_INTERFACE_PLUGIN_SILK_DNS_SERVERS}" \
  --arg container_networking_interface_plugin_silk_enable_log_traffic "${CONTAINER_NETWORKING_INTERFACE_PLUGIN_SILK_ENABLE_LOG_TRAFFIC:-true}" \
  --arg container_networking_interface_plugin_silk_iptables_accepted_udp_logs_per_sec "${CONTAINER_NETWORKING_INTERFACE_PLUGIN_SILK_IPTABLES_ACCEPTED_UDP_LOGS_PER_SEC:-100}" \
  --arg container_networking_interface_plugin_silk_iptables_denied_logs_per_sec "${CONTAINER_NETWORKING_INTERFACE_PLUGIN_SILK_IPTABLES_DENIED_LOGS_PER_SEC:-1}" \
  --arg container_networking_interface_plugin_silk_network_cidr "${CONTAINER_NETWORKING_INTERFACE_PLUGIN_SILK_NETWORK_CIDR:-"10.255.0.0/16"}" \
  --arg container_networking_interface_plugin_silk_network_mtu "${CONTAINER_NETWORKING_INTERFACE_PLUGIN_SILK_NETWORK_MTU:-1454}" \
  --arg container_networking_interface_plugin_silk_vtep_port "${CONTAINER_NETWORKING_INTERFACE_PLUGIN_SILK_VTEP_PORT:-4789}" \
  --arg credhub_database "${CREDHUB_DATABASE:-"internal_mysql"}" \
  --arg credhub_database_external_host "${CREDHUB_DATABASE_EXTERNAL_HOST:-""}" \
  --arg credhub_database_external_password "${CREDHUB_DATABASE_EXTERNAL_PASSWORD}" \
  --arg credhub_database_external_port "${CREDHUB_DATABASE_EXTERNAL_PORT:-""}" \
  --arg credhub_database_external_tls_ca "${CREDHUB_DATABASE_EXTERNAL_TLS_CA:-""}" \
  --arg credhub_database_external_username "${CREDHUB_DATABASE_EXTERNAL_USERNAME:-""}" \
  --arg credhub_hsm_provider_client_certificate "${CREDHUB_HSM_PROVIDER_CLIENT_CERTIFICATE}" \
  --arg credhub_hsm_provider_client_private_key "${CREDHUB_HSM_PROVIDER_CLIENT_PRIVATE_KEY}" \
  --arg credhub_hsm_provider_partition "${CREDHUB_HSM_PROVIDER_PARTITION:-""}" \
  --arg credhub_hsm_provider_partition_password "${CREDHUB_HSM_PROVIDER_PARTITION_PASSWORD}" \
  --argjson credhub_hsm_provider_servers ${CREDHUB_HSM_PROVIDER_SERVERS} \
  --arg credhub_key_encryption_name "${CREDHUB_KEY_ENCRYPTION_NAME:-"Generated"}" \
  --arg credhub_key_encryption_secret "${CREDHUB_KEY_ENCRYPTION_SECRET:-"Thisisasupersecretkey2018"}" \
  --arg credhub_key_encryption_is_primary "${CREDHUB_KEY_ENCRYPTION_IS_PRIMARY:-true}" \
  --arg enable_grootfs "${ENABLE_GROOTFS:-true}" \
  --arg enable_service_discovery_for_apps "${ENABLE_SERVICE_DISCOVERY_FOR_APPS:-false}" \
  --arg garden_disk_cleanup "${GARDEN_DISK_CLEANUP:-"threshold"}" \
  --arg gorouter_ssl_ciphers "${GOROUTER_SSL_CIPHERS:-"ECDHE-RSA-AES128-GCM-SHA256:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"}" \
  --arg haproxy_forward_tls "${HAPROXY_FORWARD_TLS:-"disable"}" \
  --arg haproxy_forward_tls_enable_backend_ca "${HAPROXY_FORWARD_TLS_ENABLE_BACKEND_CA:-""}" \
  --arg haproxy_hsts_support "${HAPROXY_HSTS_SUPPORT:-"disable"}" \
  --arg haproxy_hsts_support_enable_enable_preload "${HAPROXY_HSTS_SUPPORT_ENABLE_ENABLE_PRELOAD:-false}" \
  --arg haproxy_hsts_support_enable_include_subdomains "${HAPROXY_HSTS_SUPPORT_ENABLE_INCLUDE_SUBDOMAINS:-false}" \
  --arg haproxy_hsts_support_enable_max_age "${HAPROXY_HSTS_SUPPORT_ENABLE_MAX_AGE:-31536000}" \
  --arg haproxy_max_buffer_size "${HAPROXY_MAX_BUFFER_SIZE:-16384}" \
  --arg haproxy_ssl_ciphers "${HAPROXY_SSL_CIPHERS:-"DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384"}" \
  --arg logger_endpoint_port "${LOGGER_ENDPOINT_PORT:-""}" \
  --arg mysql_activity_logging "${MYSQL_ACTIVITY_LOGGING:-"enable"}" \
  --arg mysql_activity_logging_enable_audit_logging_events "${MYSQL_ACTIVITY_LOGGING_ENABLE_AUDIT_LOGGING_EVENTS:-"connect,query"}" \
  --arg networking_poe_ssl_name "${NETWORKING_POE_SSL_NAME}" \
  --arg networking_poe_ssl_cert_pem "${NETWORKING_POE_SSL_CERT_PEM}" \
  --arg networking_poe_ssl_cert_private_key_pem "${NETWORKING_POE_SSL_CERT_PRIVATE_KEY_PEM}" \
  --arg nfs_volume_driver "${NFS_VOLUME_DRIVER:-"disable"}" \
  --arg nfs_volume_driver_enable_ldap_server_host "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVER_HOST:-""}" \
  --arg nfs_volume_driver_enable_ldap_server_port "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVER_PORT:-""}" \
  --arg nfs_volume_driver_enable_ldap_service_account_password "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVICE_ACCOUNT_PASSWORD}" \
  --arg nfs_volume_driver_enable_ldap_service_account_user "${NFS_VOLUME_DRIVER_ENABLE_LDAP_SERVICE_ACCOUNT_USER:-""}" \
  --arg nfs_volume_driver_enable_ldap_user_fqdn "${NFS_VOLUME_DRIVER_ENABLE_LDAP_USER_FQDN:-""}" \
  --arg push_apps_manager_accent_color "${PUSH_APPS_MANAGER_ACCENT_COLOR:-""}" \
  --arg push_apps_manager_company_name "${PUSH_APPS_MANAGER_COMPANY_NAME:-""}" \
  --arg push_apps_manager_currency_lookup "${PUSH_APPS_MANAGER_CURRENCY_LOOKUP:-{ \"usd\": \"$\", \"eur\": \"€\" }}" \
  --arg push_apps_manager_display_plan_prices "${PUSH_APPS_MANAGER_DISPLAY_PLAN_PRICES:-false}" \
  --arg push_apps_manager_enable_invitations "${PUSH_APPS_MANAGER_ENABLE_INVITATIONS:-true}" \
  --arg push_apps_manager_favicon "${PUSH_APPS_MANAGER_FAVICON:-""}" \
  --argjson push_apps_manager_footer_links ${PUSH_APPS_MANAGER_FOOTER_LINKS} \
  --arg push_apps_manager_footer_text "${PUSH_APPS_MANAGER_FOOTER_TEXT:-""}" \
  --arg push_apps_manager_global_wrapper_bg_color "${PUSH_APPS_MANAGER_GLOBAL_WRAPPER_BG_COLOR:-""}" \
  --arg push_apps_manager_global_wrapper_footer_content "${PUSH_APPS_MANAGER_GLOBAL_WRAPPER_FOOTER_CONTENT:-""}" \
  --arg push_apps_manager_global_wrapper_header_content "${PUSH_APPS_MANAGER_GLOBAL_WRAPPER_HEADER_CONTENT:-""}" \
  --arg push_apps_manager_global_wrapper_text_color "${PUSH_APPS_MANAGER_GLOBAL_WRAPPER_TEXT_COLOR:-""}" \
  --arg push_apps_manager_logo "${PUSH_APPS_MANAGER_LOGO:-""}" \
  --arg push_apps_manager_marketplace_name "${PUSH_APPS_MANAGER_MARKETPLACE_NAME:-""}" \
  --arg push_apps_manager_nav_link_name_1 "${PUSH_APPS_MANAGER_NAV_LINK_NAME_1:-"Marketplace"}" \
  --arg push_apps_manager_nav_link_href_1 "${PUSH_APPS_MANAGER_NAV_LINK_HREF_1:-"/marketplace"}" \
  --arg push_apps_manager_nav_link_name_2 "${PUSH_APPS_MANAGER_NAV_LINK_NAME_2:-"Docs"}" \
  --arg push_apps_manager_nav_link_href_2 "${PUSH_APPS_MANAGER_NAV_LINK_HREF_2:-"https://docs.pivotal.io/pivotalcf/2-1/pas/intro.html"}" \
  --arg push_apps_manager_nav_link_name_3 "${PUSH_APPS_MANAGER_NAV_LINK_NAME_3:-"Tools"}" \
  --arg push_apps_manager_nav_link_href_3 "${PUSH_APPS_MANAGER_NAV_LINK_HREF_3:-"/tools"}" \
  --arg push_apps_manager_product_name "${PUSH_APPS_MANAGER_PRODUCT_NAME:-""}" \
  --arg push_apps_manager_square_logo "${PUSH_APPS_MANAGER_SQUARE_LOGO:-""}" \
  --arg rep_proxy_enabled "${REP_PROXY_ENABLED:-false}" \
  --arg route_services "${ROUTE_SERVICES:-"enable"}" \
  --arg route_services_enable_ignore_ssl_cert_verification "${ROUTE_SERVICES_ENABLE_IGNORE_SSL_CERT_VERIFICATION:-true}" \
  --arg router_backend_max_conn "${ROUTER_BACKEND_MAX_CONN:-500}" \
  --arg router_client_cert_validation "${ROUTER_CLIENT_CERT_VALIDATION:-"request"}" \
  --arg router_enable_proxy "${ROUTER_ENABLE_PROXY:-false}" \
  --arg router_keepalive_connections "${ROUTER_KEEPALIVE_CONNECTIONS:-"enable"}" \
  --arg routing_custom_ca_certificates "${ROUTING_CUSTOM_CA_CERTIFICATES:-""}" \
  --arg routing_disable_http "${ROUTING_DISABLE_HTTP:-false}" \
  --arg routing_minimum_tls_version "${ROUTING_MINIMUM_TLS_VERSION:-"tls_v1_2"}" \
  --arg routing_tls_termination "${ROUTING_TLS_TERMINATION:-"router"}" \
  --arg saml_entity_id_override "${SAML_ENTITY_ID_OVERRIDE:-""}" \
  --arg saml_signature_algorithm "${SAML_SIGNATURE_ALGORITHM:-"SHA256"}" \
  --arg secure_service_instance_credentials "${SECURE_SERVICE_INSTANCE_CREDENTIALS:-false}" \
  --arg security_acknowledgement "${SECURITY_ACKNOWLEDGEMENT:-""}" \
  --arg smoke_tests "${SMOKE_TESTS:-"on_demand"}" \
  --arg smoke_tests_specified_apps_domain "${SMOKE_TESTS_SPECIFIED_APPS_DOMAIN:-""}" \
  --arg smoke_tests_specified_org_name "${SMOKE_TESTS_SPECIFIED_ORG_NAME:-""}" \
  --arg smoke_tests_specified_space_name "${SMOKE_TESTS_SPECIFIED_SPACE_NAME:-""}" \
  --arg smtp_address "${SMTP_ADDRESS:-""}" \
  --arg smtp_auth_mechanism "${SMTP_AUTH_MECHANISM:-"none"}" \
  --arg smtp_crammd5_secret "${SMTP_CRAMMD5_SECRET:-""}" \
  --arg smtp_user "${SMTP_USER:-""}" \
  --arg smtp_password "${SMTP_PASSWORD:-""}" \
  --arg smtp_enable_starttls_auto "${SMTP_ENABLE_STARTTLS_AUTO:-false}" \
  --arg smtp_from "${SMTP_FROM:-""}" \
  --arg smtp_port "${SMTP_PORT:-587}" \
  --arg syslog_host "${SYSLOG_HOST:-""}" \
  --arg syslog_metrics_to_syslog_enabled "${SYSLOG_METRICS_TO_SYSLOG_ENABLED:-false}" \
  --arg syslog_port "${SYSLOG_PORT:-5514}" \
  --arg syslog_protocol "${SYSLOG_PROTOCOL:-"relp"}" \
  --arg syslog_rule "${SYSLOG_RULE:-""}" \
  --arg syslog_tls "${SYSLOG_TLS:-"disabled"}" \
  --arg syslog_tls_enabled_tls_ca_cert "${SYSLOG_TLS_ENABLED_TLS_CA_CERT:-""}" \
  --arg syslog_tls_enabled_tls_permitted_peer "${SYSLOG_TLS_ENABLED_TLS_PERMITTED_PEER:-""}" \
  --arg syslog_use_tcp_for_file_forwarding_local_transport "${SYSLOG_USE_TCP_FOR_FILE_FORWARDING_LOCAL_TRANSPORT:-false}" \
  --arg system_blobstore "${SYSTEM_BLOBSTORE:-"internal"}" \
  --arg system_blobstore_external_access_key "${SYSTEM_BLOBSTORE_EXTERNAL_ACCESS_KEY:-""}" \
  --arg system_blobstore_external_buildpacks_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_BUILDPACKS_BUCKET:-""}" \
  --arg system_blobstore_external_droplets_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_DROPLETS_BUCKET:-""}" \
  --arg system_blobstore_external_encryption "${SYSTEM_BLOBSTORE_EXTERNAL_ENCRYPTION:-false}" \
  --arg system_blobstore_external_encryption_kms_key_id "${SYSTEM_BLOBSTORE_EXTERNAL_ENCRYPTION_KMS_KEY_ID:-""}" \
  --arg system_blobstore_external_endpoint "${SYSTEM_BLOBSTORE_EXTERNAL_ENDPOINT:-"https://s3.amazonaws.com"}" \
  --arg system_blobstore_external_packages_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_PACKAGES_BUCKET:-""}" \
  --arg system_blobstore_external_region "${SYSTEM_BLOBSTORE_EXTERNAL_REGION:-""}" \
  --arg system_blobstore_external_resources_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_RESOURCES_BUCKET:-""}" \
  --arg system_blobstore_external_secret_key "${SYSTEM_BLOBSTORE_EXTERNAL_SECRET_KEY}" \
  --arg system_blobstore_external_signature_version "${SYSTEM_BLOBSTORE_EXTERNAL_SIGNATURE_VERSION:-4}" \
  --arg system_blobstore_external_versioning "${SYSTEM_BLOBSTORE_EXTERNAL_VERSIONING:-false}" \
  --arg system_blobstore_external_azure_access_key "${SYSTEM_BLOBSTORE_EXTERNAL_AZURE_ACCESS_KEY}" \
  --arg system_blobstore_external_azure_account_name "${SYSTEM_BLOBSTORE_EXTERNAL_AZURE_ACCOUNT_NAME:-""}" \
  --arg system_blobstore_external_azure_buildpacks_container "${SYSTEM_BLOBSTORE_EXTERNAL_AZURE_BUILDPACKS_CONTAINER:-""}" \
  --arg system_blobstore_external_azure_droplets_container "${SYSTEM_BLOBSTORE_EXTERNAL_AZURE_DROPLETS_CONTAINER:-""}" \
  --arg system_blobstore_external_azure_environment "${SYSTEM_BLOBSTORE_EXTERNAL_AZURE_ENVIRONMENT:-"AzureCloud"}" \
  --arg system_blobstore_external_azure_packages_container "${SYSTEM_BLOBSTORE_EXTERNAL_AZURE_PACKAGES_CONTAINER:-""}" \
  --arg system_blobstore_external_azure_resources_container "${SYSTEM_BLOBSTORE_EXTERNAL_AZURE_RESOURCES_CONTAINER:-""}" \
  --arg system_blobstore_external_gcs_access_key "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_ACCESS_KEY:-""}" \
  --arg system_blobstore_external_gcs_buildpacks_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_BUILDPACKS_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_droplets_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_DROPLETS_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_packages_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_PACKAGES_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_resources_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_RESOURCES_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_secret_key "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SECRET_KEY}" \
  --arg system_blobstore_external_gcs_service_account_buildpacks_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SERVICE_ACCOUNT_BUILDPACKS_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_service_account_droplets_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SERVICE_ACCOUNT_DROPLETS_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_service_account_packages_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SERVICE_ACCOUNT_PACKAGES_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_service_account_project_id "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SERVICE_ACCOUNT_PROJECT_ID:-""}" \
  --arg system_blobstore_external_gcs_service_account_resources_bucket "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SERVICE_ACCOUNT_RESOURCES_BUCKET:-""}" \
  --arg system_blobstore_external_gcs_service_account_service_account_email "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SERVICE_ACCOUNT_SERVICE_ACCOUNT_EMAIL:-""}" \
  --arg system_blobstore_external_gcs_service_account_service_account_json_key "${SYSTEM_BLOBSTORE_EXTERNAL_GCS_SERVICE_ACCOUNT_SERVICE_ACCOUNT_JSON_KEY:-""}" \
  --arg system_database "${SYSTEM_DATABASE:-"internal_mysql"}" \
  --arg system_database_external_account_password "${SYSTEM_DATABASE_EXTERNAL_ACCOUNT_PASSWORD}" \
  --arg system_database_external_account_username "${SYSTEM_DATABASE_EXTERNAL_ACCOUNT_USERNAME:-""}" \
  --arg system_database_external_app_usage_service_password "${SYSTEM_DATABASE_EXTERNAL_APP_USAGE_SERVICE_PASSWORD}" \
  --arg system_database_external_app_usage_service_username "${SYSTEM_DATABASE_EXTERNAL_APP_USAGE_SERVICE_USERNAME:-""}" \
  --arg system_database_external_autoscale_password "${SYSTEM_DATABASE_EXTERNAL_AUTOSCALE_PASSWORD}" \
  --arg system_database_external_autoscale_username "${SYSTEM_DATABASE_EXTERNAL_AUTOSCALE_USERNAME:-""}" \
  --arg system_database_external_ccdb_password "${SYSTEM_DATABASE_EXTERNAL_CCDB_PASSWORD}" \
  --arg system_database_external_ccdb_username "${SYSTEM_DATABASE_EXTERNAL_CCDB_USERNAME:-""}" \
  --arg system_database_external_diego_password "${SYSTEM_DATABASE_EXTERNAL_DIEGO_PASSWORD}" \
  --arg system_database_external_diego_username "${SYSTEM_DATABASE_EXTERNAL_DIEGO_USERNAME:-""}" \
  --arg system_database_external_host "${SYSTEM_DATABASE_EXTERNAL_HOST:-""}" \
  --arg system_database_external_locket_password "${SYSTEM_DATABASE_EXTERNAL_LOCKET_PASSWORD}" \
  --arg system_database_external_locket_username "${SYSTEM_DATABASE_EXTERNAL_LOCKET_USERNAME:-""}" \
  --arg system_database_external_networkpolicyserver_password "${SYSTEM_DATABASE_EXTERNAL_NETWORKPOLICYSERVER_PASSWORD}" \
  --arg system_database_external_networkpolicyserver_username "${SYSTEM_DATABASE_EXTERNAL_NETWORKPOLICYSERVER_USERNAME:-""}" \
  --arg system_database_external_nfsvolume_password "${SYSTEM_DATABASE_EXTERNAL_NFSVOLUME_PASSWORD}" \
  --arg system_database_external_nfsvolume_username "${SYSTEM_DATABASE_EXTERNAL_NFSVOLUME_USERNAME:-""}" \
  --arg system_database_external_notifications_password "${SYSTEM_DATABASE_EXTERNAL_NOTIFICATIONS_PASSWORD}" \
  --arg system_database_external_notifications_username "${SYSTEM_DATABASE_EXTERNAL_NOTIFICATIONS_USERNAME:-""}" \
  --arg system_database_external_port "${SYSTEM_DATABASE_EXTERNAL_PORT:-""}" \
  --arg system_database_external_routing_password "${SYSTEM_DATABASE_EXTERNAL_ROUTING_PASSWORD}" \
  --arg system_database_external_routing_username "${SYSTEM_DATABASE_EXTERNAL_ROUTING_USERNAME:-""}" \
  --arg system_database_external_silk_password "${SYSTEM_DATABASE_EXTERNAL_SILK_PASSWORD}" \
  --arg system_database_external_silk_username "${SYSTEM_DATABASE_EXTERNAL_SILK_USERNAME:-""}" \
  --arg tcp_routing "${TCP_ROUTING:-"disable"}" \
  --arg tcp_routing_enable_reservable_ports "${TCP_ROUTING_ENABLE_RESERVABLE_PORTS:-""}" \
  --arg uaa "${UAA:-"internal"}" \
  --arg uaa_internal_password_expires_after_months "${UAA_INTERNAL_PASSWORD_EXPIRES_AFTER_MONTHS:-0}" \
  --arg uaa_internal_password_max_retry "${UAA_INTERNAL_PASSWORD_MAX_RETRY:-5}" \
  --arg uaa_internal_password_min_length "${UAA_INTERNAL_PASSWORD_MIN_LENGTH:-0}" \
  --arg uaa_internal_password_min_lowercase "${UAA_INTERNAL_PASSWORD_MIN_LOWERCASE:-0}" \
  --arg uaa_internal_password_min_numeric "${UAA_INTERNAL_PASSWORD_MIN_NUMERIC:-0}" \
  --arg uaa_internal_password_min_special "${UAA_INTERNAL_PASSWORD_MIN_SPECIAL:-0}" \
  --arg uaa_internal_password_min_uppercase "${UAA_INTERNAL_PASSWORD_MIN_UPPERCASE:-0}" \
  --arg uaa_ldap_identity "$UAA_LDAP_IDENTITY" \
  --arg uaa_ldap_password "$UAA_LDAP_PASSWORD" \
  --arg uaa_ldap_email_domains "${UAA_LDAP_EMAIL_DOMAINS:-""}" \
  --arg uaa_ldap_first_name_attribute "${UAA_LDAP_FIRST_NAME_ATTRIBUTE:-""}" \
  --arg uaa_ldap_group_search_base "${UAA_LDAP_GROUP_SEARCH_BASE:-""}" \
  --arg uaa_ldap_group_search_filter "${UAA_LDAP_GROUP_SEARCH_FILTER:-""}" \
  --arg uaa_ldap_last_name_attribute "${UAA_LDAP_LAST_NAME_ATTRIBUTE:-""}" \
  --arg uaa_ldap_ldap_referrals "${UAA_LDAP_LDAP_REFERRALS:-"follow"}" \
  --arg uaa_ldap_mail_attribute_name "${UAA_LDAP_MAIL_ATTRIBUTE_NAME:-"mail"}" \
  --arg uaa_ldap_search_base "${UAA_LDAP_SEARCH_BASE:-""}" \
  --arg uaa_ldap_search_filter "${UAA_LDAP_SEARCH_FILTER:-"mail={0}"}" \
  --arg uaa_ldap_server_ssl_cert "${UAA_LDAP_SERVER_SSL_CERT:-""}" \
  --arg uaa_ldap_server_ssl_cert_alias "${UAA_LDAP_SERVER_SSL_CERT_ALIAS:-""}" \
  --arg uaa_ldap_url "${UAA_LDAP_URL:-""}" \
  --arg uaa_saml_display_name "${UAA_SAML_DISPLAY_NAME:-""}" \
  --arg uaa_saml_email_attribute "${UAA_SAML_EMAIL_ATTRIBUTE:-""}" \
  --arg uaa_saml_email_domains "${UAA_SAML_EMAIL_DOMAINS:-""}" \
  --arg uaa_saml_entity_id_override "${UAA_SAML_ENTITY_ID_OVERRIDE:-""}" \
  --arg uaa_saml_external_groups_attribute "${UAA_SAML_EXTERNAL_GROUPS_ATTRIBUTE:-""}" \
  --arg uaa_saml_first_name_attribute "${UAA_SAML_FIRST_NAME_ATTRIBUTE:-""}" \
  --arg uaa_saml_last_name_attribute "${UAA_SAML_LAST_NAME_ATTRIBUTE:-""}" \
  --arg uaa_saml_name_id_format "${UAA_SAML_NAME_ID_FORMAT:-"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"}" \
  --arg uaa_saml_require_signed_assertions "${UAA_SAML_REQUIRE_SIGNED_ASSERTIONS:-false}" \
  --arg uaa_saml_sign_auth_requests "${UAA_SAML_SIGN_AUTH_REQUESTS:-true}" \
  --arg uaa_saml_sso_name "${UAA_SAML_SSO_NAME:-""}" \
  --arg uaa_saml_sso_url "${UAA_SAML_SSO_URL:-""}" \
  --arg uaa_saml_sso_xml "${UAA_SAML_SSO_XML:-""}" \
  --arg uaa_database "${UAA_DATABASE:-"internal_mysql"}" \
  --arg uaa_database_external_host "${UAA_DATABASE_EXTERNAL_HOST:-""}" \
  --arg uaa_database_external_port "${UAA_DATABASE_EXTERNAL_PORT:-""}" \
  --arg uaa_database_external_uaa_password "${UAA_DATABASE_EXTERNAL_UAA_PASSWORD}" \
  --arg uaa_database_external_uaa_username "${UAA_DATABASE_EXTERNAL_UAA_USERNAME:-""}" \
  --arg uaa_session_cookie_max_age "${UAA_SESSION_COOKIE_MAX_AGE:-1800}" \
  --arg uaa_session_idle_timeout "${UAA_SESSION_IDLE_TIMEOUT:-1800}" \
  --arg router_disable_insecure_cookies "${ROUTER_DISABLE_INSECURE_COOKIES:-false}" \
  --arg router_drain_wait "${ROUTER_DRAIN_WAIT:-20}" \
  --arg router_enable_isolated_routing "${ROUTER_ENABLE_ISOLATED_ROUTING:-false}" \
  --arg router_enable_write_access_logs "${ROUTER_ENABLE_WRITE_ACCESS_LOGS:-true}" \
  --arg router_enable_zipkin "${ROUTER_ENABLE_ZIPKIN:-true}" \
  --arg router_extra_headers_to_log "${ROUTER_EXTRA_HEADERS_TO_LOG:-""}" \
  --arg router_frontend_idle_timeout "${ROUTER_FRONTEND_IDLE_TIMEOUT:-900}" \
  --arg router_lb_healthy_threshold "${ROUTER_LB_HEALTHY_THRESHOLD:-20}" \
  --arg router_request_timeout_in_seconds "${ROUTER_REQUEST_TIMEOUT_IN_SECONDS:-900}" \
  --arg router_static_ips "${ROUTER_STATIC_IPS:-""}" \
  --arg tcp_router_static_ips "${TCP_ROUTER_STATIC_IPS:-""}" \
  --arg uaa_apps_manager_access_token_lifetime "${UAA_APPS_MANAGER_ACCESS_TOKEN_LIFETIME:-1209600}" \
  --arg uaa_apps_manager_refresh_token_lifetime "${UAA_APPS_MANAGER_REFRESH_TOKEN_LIFETIME:-1209600}" \
  --arg uaa_cf_cli_access_token_lifetime "${UAA_CF_CLI_ACCESS_TOKEN_LIFETIME:-7200}" \
  --arg uaa_cf_cli_refresh_token_lifetime "${UAA_CF_CLI_REFRESH_TOKEN_LIFETIME:-1209600}" \
  --arg uaa_customize_password_label "${UAA_CUSTOMIZE_PASSWORD_LABEL:-"Email"}" \
  --arg uaa_customize_username_label "${UAA_CUSTOMIZE_USERNAME_LABEL:-"Password"}" \
  --arg uaa_issuer_uri "${UAA_ISSUER_URI:-""}" \
  --arg uaa_proxy_ips_regex "${UAA_PROXY_IPS_REGEX:-''}" \
  --arg uaa_private_key_pem "$UAA_PRIVATE_KEY_PEM" \
  --arg uaa_cert_pem "$UAA_CERT_PEM" \
  --arg uaa_service_provider_key_password "${UAA_SERVICE_PROVIDER_KEY_PASSWORD}" \
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
    "value": $cc_api_rate_limit_enable_general_limit
  },
  ".properties.cc_api_rate_limit.enable.unauthenticated_limit": {
    "value": $cc_api_rate_limit_enable_unauthenticated_limit
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
    "value": $container_networking_interface_plugin_silk_network_mtu
  },
  ".properties.container_networking_interface_plugin.silk.network_cidr": {
    "value": $container_networking_interface_plugin_silk_network_cidr
  },
  ".properties.container_networking_interface_plugin.silk.vtep_port": {
    "value": $container_networking_interface_plugin_silk_vtep_port
  },
  ".properties.container_networking_interface_plugin.silk.iptables_denied_logs_per_sec": {
    "value": $container_networking_interface_plugin_silk_iptables_denied_logs_per_sec
  },
  ".properties.container_networking_interface_plugin.silk.iptables_accepted_udp_logs_per_sec": {
    "value": $container_networking_interface_plugin_silk_iptables_accepted_udp_logs_per_sec
  },
  ".properties.container_networking_interface_plugin.silk.enable_log_traffic": {
    "value": $container_networking_interface_plugin_silk_enable_log_traffic
  },
  ".properties.container_networking_interface_plugin.silk.dns_servers": {
    "value": $container_networking_interface_plugin_silk_dns_servers
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
  ".properties.credhub_hsm_provider_client_certificate": {
    "value": {
      "cert_pem": $credhub_hsm_provider_client_certificate,
      "private_key_pem": $credhub_hsm_provider_client_private_key
    }
  },
  ".properties.credhub_hsm_provider_partition": {
    "value": $credhub_hsm_provider_partition
  },
  ".properties.credhub_hsm_provider_partition_password": {
    "value": {
      "secret": $credhub_hsm_provider_partition_password
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
    "value": $haproxy_forward_tls_enable_backend_ca
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
+
if $haproxy_hsts_support == "enable" then
{
  ".properties.haproxy_hsts_support.enable.max_age": {
    "value": $haproxy_hsts_support_enable_max_age
  },
  ".properties.haproxy_hsts_support.enable.include_subdomains": {
    "value": $haproxy_hsts_support_enable_include_subdomains
  },
  ".properties.haproxy_hsts_support.enable.enable_preload": {
    "value": $haproxy_hsts_support_enable_enable_preload
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
+
if $mysql_activity_logging == "enable" then
{
  ".properties.mysql_activity_logging.enable.audit_logging_events": {
    "value": $mysql_activity_logging_enable_audit_logging_events
  }
}
else .
end
+
{
  ".properties.networking_poe_ssl_certs": {
    "value": [
      {
        "name": $networking_poe_ssl_name,
        "certificate": {
          "cert_pem":$networking_poe_ssl_cert_pem,
          "private_key_pem":$networking_poe_ssl_cert_private_key_pem
        }
      }
    ]
  },
  ".properties.nfs_volume_driver": {
    "value": $nfs_volume_driver
  }
}
+
if $nfs_volume_driver == "enable" then
{
  ".properties.nfs_volume_driver.enable.ldap_service_account_user": {
    "value": $nfs_volume_driver_enable_ldap_service_account_user
  },
  ".properties.nfs_volume_driver.enable.ldap_service_account_password": {
    "value": {
      "secret": $nfs_volume_driver_enable_ldap_service_account_password
    }
  },
  ".properties.nfs_volume_driver.enable.ldap_server_host": {
    "value": $nfs_volume_driver_enable_ldap_server_host
  },
  ".properties.nfs_volume_driver.enable.ldap_server_port": {
    "value": $nfs_volume_driver_enable_ldap_server_port
  },
  ".properties.nfs_volume_driver.enable.ldap_user_fqdn": {
    "value": $nfs_volume_driver_enable_ldap_user_fqdn
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
    "value": [
      {
        "name": $push_apps_manager_nav_link_name_1,
        "href": $push_apps_manager_nav_link_href_1
      },
      {
        "name": $push_apps_manager_nav_link_name_2,
        "href": $push_apps_manager_nav_link_href_2
      },
      {
        "name": $push_apps_manager_nav_link_name_3,
        "href": $push_apps_manager_nav_link_href_3
      }
    ]
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
+
if $route_services == "enable" then
{
  ".properties.route_services.enable.ignore_ssl_cert_verification": {
    "value": $route_services_enable_ignore_ssl_cert_verification
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
    "value": $smoke_tests_specified_org_name
  },
  ".properties.smoke_tests.specified.space_name": {
    "value": $smoke_tests_specified_space_name
  },
  ".properties.smoke_tests.specified.apps_domain": {
    "value": $smoke_tests_specified_apps_domain
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
      "identity": $smtp_user,
      "password": $smtp_password
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
    "value": $syslog_tls_enabled_tls_ca_cert
  },
  ".properties.syslog_tls.enabled.tls_permitted_peer": {
    "value": $syslog_tls_enabled_tls_permitted_peer
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
  },
  ".properties.system_blobstore.external_gcs_service_account.buildpacks_bucket": {
    "value": $system_blobstore_external_gcs_service_account_buildpacks_bucket
  },
  ".properties.system_blobstore.external_gcs_service_account.droplets_bucket": {
    "value": $system_blobstore_external_gcs_service_account_droplets_bucket
  },
  ".properties.system_blobstore.external_gcs_service_account.packages_bucket": {
    "value": $system_blobstore_external_gcs_service_account_packages_bucket
  },
  ".properties.system_blobstore.external_gcs_service_account.resources_bucket": {
    "value": $system_blobstore_external_gcs_service_account_resources_bucket
  },
  ".properties.system_blobstore.external_gcs_service_account.project_id": {
    "value": $system_blobstore_external_gcs_service_account_project_id
  },
  ".properties.system_blobstore.external_gcs_service_account.service_account_email": {
    "value": $system_blobstore_external_gcs_service_account_service_account_email
  },
  ".properties.system_blobstore.external_gcs_service_account.service_account_json_key": {
    "value": $system_blobstore_external_gcs_service_account_service_account_json_key
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
    "value": $tcp_routing_enable_reservable_ports
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
    "value":{
      "identity": $uaa_ldap_identity,
      "password": $uaa_ldap_password
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
  ".properties.uaa_session_cookie_max_age": {
    "value": $uaa_session_cookie_max_age
  },
  ".properties.uaa_session_idle_timeout": {
    "value": $uaa_session_idle_timeout
  },
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

resources_config="{
  \"consul_server\": {\"instances\": ${CONSUL_SERVER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${CONSUL_SERVER_INSTANCE_TYPE:-micro}\"}, \"persistent_disk\": { \"size_mb\": \"${CONSUL_SERVER_PERSISTENT_DISK_MB:-1024}\"}},
  \"nats\": {\"instances\": ${NATS_INSTANCES:-2}, \"instance_type\": { \"id\": \"${NATS_INSTANCE_TYPE:-micro}\"}},
  \"nfs_server\": {\"instances\": ${NFS_SERVER_INSTANCES:-1}, \"instance_type\": { \"id\": \"${NFS_SERVER_INSTANCE_TYPE:-medium.mem}\"}, \"persistent_disk\": { \"size_mb\": \"${NFS_SERVER_PERSISTENT_DISK_MB:-102400}\"}},
  \"mysql_proxy\": {\"instances\": ${MYSQL_PROXY_INSTANCES:-2}, \"instance_type\": { \"id\": \"${MYSQL_PROXY_INSTANCE_TYPE:-micro}\"}},
  \"mysql\": {\"instances\": ${MYSQL_INSTANCES:-3}, \"instance_type\": { \"id\": \"${MYSQL_INSTANCE_TYPE:-large.disk}\"}, \"persistent_disk\": { \"size_mb\": \"${MYSQL_PERSISTENT_DISK_MB:-102400}\"}},
  \"backup-prepare\": {\"instances\": ${BACKUP_PREPARE_INSTANCES:-1}, \"instance_type\": { \"id\": \"${BACKUP_PREPARE_INSTANCE_TYPE:-micro}\"}, \"persistent_disk\": { \"size_mb\": \"${BACKUP_PREPARE_PERSISTENT_DISK_MB:-204800}\"}},
  \"diego_database\": {\"instances\": ${DIEGO_DATABASE_INSTANCES:-3}, \"instance_type\": { \"id\": \"${DIEGO_DATABASE_INSTANCE_TYPE:-micro}\"}},
  \"uaa\": {\"instances\": ${UAA_INSTANCES:-2}, \"instance_type\": { \"id\": \"${UAA_INSTANCE_TYPE:-medium.disk}\"}},
  \"cloud_controller\": {\"instances\": ${CLOUD_CONTROLLER_INSTANCES:-2}, \"instance_type\": { \"id\": \"${CLOUD_CONTROLLER_INSTANCE_TYPE:-medium.disk}\"}},
  \"ha_proxy\": {\"instances\": ${HA_PROXY_INSTANCES:-1}, \"instance_type\": { \"id\": \"${HA_PROXY_INSTANCE_TYPE:-micro}\"}},
  \"router\": {\"instances\": ${ROUTER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${ROUTER_INSTANCE_TYPE:-micro}\"}},
  \"mysql_monitor\": {\"instances\": ${MYSQL_MONITOR_INSTANCES:-1}, \"instance_type\": { \"id\": \"${MYSQL_MONITOR_INSTANCE_TYPE:-micro}\"}},
  \"clock_global\": {\"instances\": ${CLOCK_GLOBAL_INSTANCES:-1}, \"instance_type\": { \"id\": \"${CLOCK_GLOBAL_INSTANCE_TYPE:-medium.disk}\"}},
  \"cloud_controller_worker\": {\"instances\": ${CLOUD_CONTROLLER_WORKER_INSTANCES:-2}, \"instance_type\": { \"id\": \"${CLOUD_CONTROLLER_WORKER_INSTANCE_TYPE:-micro}\"}},
  \"diego_brain\": {\"instances\": ${DIEGO_BRAIN_INSTANCES:-3}, \"instance_type\": { \"id\": \"${DIEGO_BRAIN_INSTANCE_TYPE:-small}\"}},
  \"diego_cell\": {\"instances\": ${DIEGO_CELL_INSTANCES:-3}, \"instance_type\": { \"id\": \"${DIEGO_CELL_INSTANCE_TYPE:-xlarge.disk}\"}},
  \"loggregator_trafficcontroller\": {\"instances\": ${LOGGREGATOR_TRAFFICCONTROLLER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${LOGGREGATOR_TRAFFICCONTROLLER_INSTANCE_TYPE:-micro}\"}},
  \"syslog_adapter\": {\"instances\": ${SYSLOG_ADAPTER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${SYSLOG_ADAPTER_INSTANCE_TYPE:-micro}\"}},
  \"syslog_scheduler\": {\"instances\": ${SYSLOG_SCHEDULER_INSTANCES:-2}, \"instance_type\": { \"id\": \"${SYSLOG_SCHEDULER_INSTANCE_TYPE:-micro}\"}},
  \"doppler\": {\"instances\": ${DOPPLER_INSTANCES:-3}, \"instance_type\": { \"id\": \"${DOPPLER_INSTANCE_TYPE:-micro}\"}},
  \"tcp_router\": {\"instances\": ${TCP_ROUTER_INSTANCES:-1}, \"instance_type\": { \"id\": \"${TCP_ROUTER_INSTANCE_TYPE:-micro}\"}, \"persistent_disk\": { \"size_mb\": \"${TCP_ROUTER_PERSISTENT_DISK_MB:-1024}\"}},
  \"credhub\": {\"instances\": ${CREDHUB_INSTANCES:-0}, \"instance_type\": { \"id\": \"${CREDHUB_INSTANCE_TYPE:-large}\"}}
}"

network_config=$($JQ_CMD -n \
  --arg network_name "$NETWORK_NAME" \
  --arg other_azs "$OTHER_AZS" \
  --arg singleton_az "$SINGLETON_JOBS_AZ" \
'
  {
    "network": {
      "name": $network_name
    },
    "other_availability_zones": ($other_azs | split(",") | map({name: .})),
    "singleton_availability_zone": {
      "name": $singleton_az
    }
  }
'
)

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-properties "$properties_config" \
  --product-network "$network_config" \
  --product-resources "$resources_config"
