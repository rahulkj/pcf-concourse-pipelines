#!/bin/bash -e

CERTIFICATES=`om -t https://opsmgr.homelab.io -u admin -p welcome -k curl -p "/api/v0/certificates" -x POST -d '{"domains": ["*.sys.homelab.io", "*.cfapps.homelab.io", "*.login.sys.homelab.io", "*.uaa.sys.homelab.io"] }'`

CERT_PEM=`echo $CERTIFICATES | jq '.certificate'`

PRIVATE_KEY=`echo $CERTIFICATES | jq '.key'`

PROPERTIES_CONFIG=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "terminate_at_router"
  },
  ".properties.networking_point_of_entry.terminate_at_router.ssl_rsa_certificate": {
    "value": {
      "private_key_pem": "${PRIVATE_KEY}",
      "cert_pem": "${CERT_PEM}"
    }
  },
  ".router.static_ips": {
    "value": "${IS_ROUTER_IP}"
  },
  ".isolated_diego_cell.garden_network_pool": {
    "value": "10.254.0.0/22"
  },
  ".isolated_diego_cell.placement_tag": {
    "value": "${PLACEMENT_TAG_NAME}"
  }
}
EOF
)

RESOURCE_CONFIG=$(cat <<-EOF
{
  "router": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  },
  "isolated_diego_cell": {
    "instance_type": {"id": "automatic"},
    "instances" : 1
  }
}
EOF
)
