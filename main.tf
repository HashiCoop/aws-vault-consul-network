provider "aws" {
  region = var.REGION
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "hashicoop"

    workspaces {
      name = "helloWorld"
    }
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "test-key"
  public_key = var.PUBLIC_KEY
}

module "consul_network" {
  source = "./modules/consul-network"

  KEY = aws_key_pair.ssh_key.key_name
}

module "vault_cluster" {
  source = "./modules/vault-cluster"

  SUBNET     = module.consul_network.subnet.id
  VPC_SG_IDS = [module.consul_network.sg.id]
  REGION     = var.REGION

  VAULT_LICENSE = var.VAULT_LICENSE
  CONSUL_HTTP_TOKEN = var.CONSUL_HTTP_TOKEN

  KEY = aws_key_pair.ssh_key.key_name
}

module "app_stack" {
  source = "./modules/app-stack" 
  
  KEY = aws_key_pair.ssh_key.key_name

  DB_USERNAME = var.DB_USERNAME
  DB_PASSWORD = var.DB_PASSWORD
}