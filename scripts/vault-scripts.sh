### Databse
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


### App
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