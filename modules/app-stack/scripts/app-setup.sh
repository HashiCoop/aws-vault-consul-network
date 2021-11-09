#!/bin/bash

echo '
data_dir = "/opt/consul"
client_addr = "127.0.0.1"
advertise_addr = "'$PRIVATE_IP'"
retry_join = ["provider=aws tag_key=consulAutoJoin tag_value=server"]
leave_on_terminate = true
enable_local_script_checks = true
' > /etc/consul.d/consul.hcl

echo '{
  "service": {
    "name": "frontend",
    "port": 80,
    "connect": {
      "sidecar_service": {
        "proxy": {
          "upstreams": [
            {
              "destination_name": "database",
              "local_bind_port": 5432
            }
          ]
        }
      }
    }
  }
}' > /etc/consul.d/frontend.json

systemctl start consul

while ! systemctl -q is-active consul; do sleep 1; done

echo '
[Unit]
Description="HashiCorp Vault - Agent"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3
Wants=consul.service

[Service]
EnvironmentFile=/etc/vault.d/vault.env
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault agent -config=/etc/vault.d/vault.hcl
WorkingDirectory=/var/tmp/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
' > /lib/systemd/system/vault-agent.service

echo '
pid_file = "/var/tmp/pidfile"

vault {
  address = "http://vault.service.consul:8200"
  retry {
    num_retries = 20
  }
}

auto_auth {
  method "aws" {
    config = {
      type = "iam"
      role = "app"
    }
  }

  sink "file" {
    config = {
      path = "/var/tmp/.token"
      mode = 604
    }
  }
}
 
template {
  source      = "/template.tpl"
  destination = "/db/creds.env"
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = true
}
' > /etc/vault.d/vault.hcl

mkdir /db
chown -R vault:vault /db

touch /template.tpl
echo '
{{ with secret "database/creds/app-db"}}
DBHOST=database.service.consul
DBPORT=5432
DBUSER={{.Data.username}}
DBPASS={{.Data.password}}
DBNAME=postgres
{{end}}
' > /template.tpl

systemctl start vault-agent 

consul connect proxy -sidecar-for frontend &&

sudo docker run -p 80:80 --env-file /db/creds.env --network=host cmelgreen/docker-flask-postgres