output "vault_url" {
  value = "http://${module.vault_cluster.public_ip}:8200"
}

output "consul_url" {
  value = "http://${module.consul_network.public_ip}:8500"
}

output "subnet_id" {
  value = module.consul_network.subnet.id
}

output "backup_subnet_id" {
  value = module.consul_network.backup_subnet.id
}

output "security_group" {
  value = module.consul_network.sg.id
}