#!/bin/bash

echo ${VAULT_LICENSE} > /etc/vault.d/vault.hclic

echo '
ui = true
storage "consul" {
    address = "0.0.0.0:8500"
    path    = "vault"
}
listener "tcp" {
    address       = "0.0.0.0:8200"
    tls_disable = true
    tls_cert_file = "/opt/vault/tls/tls.crt"
    tls_key_file  = "/opt/vault/tls/tls.key"
}
license_path = "/etc/vault.d/vault.hclic"
seal "awskms" {
    region = "${AWS_REGION}"
    kms_key_id = "${KMS_KEY}"
}
' > /etc/vault.d/vault.hcl

echo '
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
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
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
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
' > /lib/systemd/system/vault.service
 
systemctl start vault

while ! systemctl -q is-active vault; do sleep 1; done

sleep 30

export VAULT_ADDR=http://127.0.0.1:8200

touch tokens.json
vault operator init -key-shares=3 -key-threshold=2 -format="json" > tokens.json
export VAULT_TOKEN=$(jq -r '.root_token' tokens.json)

echo $VAULT_ADDR
echo $VAULT_TOKEN

vault auth enable aws

echo '
path "auth/token/lookup-self" {
    capabilities = ["read"]
}

path "database/creds/app-db" {
    capabilities = ["read"]
}
' | vault policy write app -

vault write \
    auth/aws/role/app \
    auth_type=iam \
    policies=app \
    max_ttl=500h \
    bound_iam_principal_arn=arn:aws:iam::711129375688:role/cmelgreen-test-app_server_iam_role

sleep 60
### Database
vault secrets enable database

vault write database/config/app-database \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@database.service.consul/postgres?sslmode=disable" \
    allowed_roles=app-db \
    username="postgres" \
    password="cmelgreen-test-pass"

vault write database/roles/app-db \
    db_name=app-database \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
