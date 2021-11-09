output "public_ip" {
    value = module.consul_server.public_ip
}

output "vpc" {
  value = module.network.vpc
}

output "subnet" {
  value = module.network.subnet
}

output "backup_subnet" {
  value = module.network.backup_subnet
}

output "sg" {
  value = module.network.sg
}