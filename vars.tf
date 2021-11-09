variable "REGION" {
  type    = string
  default = "us-west-2"
}

variable "VAULT_LICENSE" {
  type = string
}

variable "DB_USERNAME" {
  type = string
}

variable "DB_PASSWORD" {
  type = string
}

variable "PUBLIC_KEY" {
  type = string
}

variable "CONSUL_HTTP_TOKEN" {}