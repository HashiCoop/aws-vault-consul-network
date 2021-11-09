#!/bin/bash

# Consul client
systemctl start consul

while ! systemctl -q is-active consul; do sleep 1; done


echo ${VAULT_LICENSE} > /etc/vault.d/vault.hclic

# Vault server
echo '
ui = true
storage "consul" {
    address = "0.0.0.0:8500"
    path    = "vault"
    token   = "${CONSUL_HTTP_TOKEN}"
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

sleep 20

export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -key-shares=3 -key-threshold=2 -format="json" > tokens.json