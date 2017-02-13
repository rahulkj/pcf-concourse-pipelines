**To use this pipeline create the params.yml file with the following variables**

```
pivnet_token:
github_token:
github_private_key:

vcenter_host:
vcenter_usr:
vcenter_pwd:
vcenter_data_center:

om_data_store:
ops_mgr_host:
ops_mgr_usr:
ops_mgr_pwd:
ops_mgr_ssh_pwd:
om_decryption_pwd:
om_ntp_servers:
om_dns_servers:
om_gateway:
om_netmask:
om_ip:

om_vm_network:
om_vm_name:
om_resource_pool:
disk_type:
om_vm_power_state:

storage_names:
network_name:
vm_network:
deployment_nw_cidr:
excluded_range:
deployment_nw_dns:
deployment_nw_gateway:

az_1_name:
az_2_name:
az_3_name:

az_1_cluster_name:
az_2_cluster_name:
az_3_cluster_name:

az_1_rp_name:
az_2_rp_name:
az_3_rp_name:

ntp_servers:
ops_dir_hostname:
loggregator_endpoint_port:
syslog_host:
syslog_port:
syslog_protocol:
ssl_cert:
ssl_private_key:
disable_http_proxy:
tcp_routing:
tcp_routing_ports:
route_services:
ignore_ssl_cert_verification:
smtp_from:
smtp_address:
smtp_port:
smtp_user:
smtp_pwd:
smtp_auth_mechanism:
ldap_url:
ldap_user:
ldap_pwd:
search_base:
search_filter:
group_search_base:
group_search_filter:
mail_attribute_name:
first_name_attribute:
last_name_attribute:
system_domain:
apps_domain:
ha_proxy_ips:
skip_cert_verify:
router_static_ips:
mysql_monitor_email:
tcp_router_static_ips:
ssh_static_ips:

jmx_admin_usr:
jmx_admin_pwd:
jmx_security_logging: true
jmx_use_ssl: false

```

Now you can execute the following commands:

* `fly -t lite login`
* `fly -t lite set-pipeline -p pcf -c pipeline.yml -l params.yml`
* `fly -t lite unpause-pipeline -p pcf`

![](./images/pipeline.png)
