#!/bin/bash

chmod +x om-cli/om-linux

CF_RELEASE=`om -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep cf`

PRODUCT_NAME=`echo $CF_RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $CF_RELEASE | cut -d"|" -f3 | tr -d " "`

om -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

CF_NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$AZ_2"
  },
  "other_availability_zones": [
    { "name": "$AZ_2" },
    { "name": "$AZ_3" }
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)


CF_PROPERTIES=$(cat <<-EOF
{
  ".properties.logger_endpoint_port": {
    "value": "$LOGGREGATOR_ENDPOINT_PORT"
  },
  ".properties.syslog_host": {
    "value": "$SYSLOG_HOST"
  },
  ".properties.syslog_port": {
    "value": "$SYSLOG_PORT"
  },
  ".properties.syslog_protocol": {
    "value": "$SYSLOG_PROTOCOL"
  },
  ".properties.networking_point_of_entry.haproxy.ssl_rsa_certificate": {
    "value": {
      "cert_pem": "$SSL_CERT",
      "private_key_pem": "$SSL_PRIVATE_KEY"
    }
  },
  ".properties.networking_point_of_entry.haproxy.disable_http": {
    "value": $DISABLE_HTTP_PROXY
  },
  ".properties.tcp_routing": {
    "value": "$TCP_ROUTING"
  },
  ".properties.tcp_routing.enable.reservable_ports": {
    "value": "$TCP_ROUTING_PORTS"
  },
  ".properties.route_services": {
    "value": "$ROUTE_SERVICES"
  },
  ".properties.route_services.enable.ignore_ssl_cert_verification": {
    "value": $IGNORE_SSL_CERT
  },
  ".properties.security_acknowledgement": {
    "value": "X"
  },
  ".properties.smtp_from": {
    "value": "$SMTP_FROM"
  },
  ".properties.smtp_address": {
    "value": "$SMTP_ADDRESS"
  },
  ".properties.smtp_port": {
    "value": "$SMTP_PORT"
  },
  ".properties.smtp_credentials": {
    "value": {
      "identity": "$SMTP_USER",
      "password": "$SMTP_PWD"
    }
  },
  ".properties.smtp_enable_starttls_auto": {
    "value": true
  },
  ".properties.smtp_auth_mechanism": {
    "value": "$SMTP_AUTH_MECHANISM"
  },
  ".properties.system_blobstore": {
    "value": "internal"
  },
  ".properties.mysql_backups": {
    "value": "disable"
  },
  ".properties.uaa": {
    "value": "ldap"
  },
  ".properties.uaa.ldap.url": {
    "value": "$LDAP_URL"
  },
  ".properties.uaa.ldap.credentials": {
    "value": {
      "identity": "$LDAP_USER",
      "password": "$LDAP_PWD"
    }
  },
  ".properties.uaa.ldap.search_base": {
    "value": "$SEARCH_BASE"
  },
  ".properties.uaa.ldap.search_filter": {
    "value": "$SEARCH_FILTER"
  },
  ".properties.uaa.ldap.group_search_base": {
    "value": "$GROUP_SEARCH_BASE"
  },
  ".properties.uaa.ldap.group_search_filter": {
    "value": "$GROUP_SEARCH_FILTER"
  },
  ".properties.uaa.ldap.mail_attribute_name": {
    "value": "$MAIL_ATTR_NAME"
  },
  ".properties.uaa.ldap.first_name_attribute": {
    "value": "$FIRST_NAME_ATTR"
  },
  ".properties.uaa.ldap.last_name_attribute": {
    "value": "$LAST_NAME_ATTR"
  },
  ".cloud_controller.system_domain": {
    "value": "$SYSTEM_DOMAIN"
  },
  ".cloud_controller.apps_domain": {
    "value": "$APPS_DOMAIN"
  },
  ".cloud_controller.default_quota_memory_limit_mb": {
    "value": 10240
  },
  ".cloud_controller.default_quota_max_number_services": {
    "value": 1000
  },
  ".cloud_controller.allow_app_ssh_access": {
    "value": true
  },
  ".cloud_controller.security_event_logging_enabled": {
    "value": true
  },
  ".ha_proxy.static_ips": {
    "value": "$HA_PROXY_IPS"
  },
  ".ha_proxy.skip_cert_verify": {
    "value": $SKIP_CERT_VERIFY
  },
  ".router.static_ips": {
    "value": "$ROUTER_STATIC_IPS"
  },
  ".router.disable_insecure_cookies": {
    "value": false
  },
  ".router.request_timeout_in_seconds": {
    "value": 900
  },
  ".mysql_monitor.recipient_email": {
    "value": "$MYSQL_MONITOR_EMAIL"
  },
  ".diego_cell.garden_network_pool": {
    "value": "10.254.0.0/22"
  },
  ".diego_cell.garden_network_mtu": {
    "value": 1454
  },
  ".doppler.message_drain_buffer_size": {
    "value": 10000
  },
  ".tcp_router.static_ips": {
    "value": "$TCP_ROUTER_STATIC_IPS"
  },
  ".push-apps-manager.company_name": {
    "value": "Homelab"
  },
  ".diego_brain.static_ips": {
    "value": "$SSH_STATIC_IPS"
  }
}
EOF
)

CF_RESOURCES=$(cat <<-EOF
{
  "consul_server": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "nats": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "etcd_tls_server": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "etcd_server": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "nfs_server": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "mysql_proxy": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "mysql": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "backup-prepare": {
    "instance_type": {"id": "automatic"},
    "instances" : 0
  },
  "ccdb": {
    "instance_type": {"id": "automatic"},
    "instances" : 0
  },
  "uaadb": {
    "instance_type": {"id": "automatic"},
    "instances" : 0
  },
  "uaa": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "cloud_controller": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "ha_proxy": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "router": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "mysql_monitor": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "clock_global": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "cloud_controller_worker": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "diego_database": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "diego_brain": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "diego_cell": {
    "instance_type": {"id": "automatic"},
    "instances" : 2
  },
  "doppler": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "loggregator_trafficcontroller": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "tcp_router": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  }
}
EOF
)

./om-cli/om-linux -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_PROPERTIES" -pn "$CF_NETWORK" -pr "$CF_RESOURCES"
