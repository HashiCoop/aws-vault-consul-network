#!/bin/bash

echo '
data_dir = "/opt/consul"
client_addr = "127.0.0.1"
advertise_addr = "'$PRIVATE_IP'"
retry_join = ["provider=aws tag_key=consulAutoJoin tag_value=server"]
leave_on_terminate = true
enable_local_script_checks = true
' > /etc/consul.d/consul.hcl

# Add an external service
sudo touch /etc/consul.d/database.json
echo '
{
  "service": {
    "id": "database1",
    "name": "database",
    "port": 5432,
    "address": "${RDS_ADDRESS}",
    "connect": {}
  },
  "check": {
    "id": "tcp",
    "name": "TCP on port 5432",
    "tcp": "${RDS_ENDPOINT}",
    "interval": "60s",
    "timeout": "3s"
  }
}
' | sudo tee /etc/consul.d/database.json
  
systemctl start consul

