#!/bin/bash

# Configure Consul
echo '
server = true
data_dir = "/opt/consul"
client_addr = "0.0.0.0"
advertise_addr = "'$PRIVATE_IP'"
bootstrap_expect = 1
ui_config = {
    enabled = true
}
acl = {
    enabled = true
    default_policy = "deny"
    enable_token_persistence = true
}
leave_on_terminate = true
connect = {
    enabled = true
}
' > /etc/consul.d/consul.hcl

systemctl start consul

while ! systemctl -q is-active consul; do sleep 1; done

sleep 15

touch bootstrap.json
consul acl bootstrap -format="json" > bootstrap.json