data "aws_ami" "vault_server_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["cmelgreen-vault-consul-base"]
  }
  owners = ["self"]
}

module "vault_server" {
  source = "../ec2"
  NAME = "cmelgreen-test-vault"
  AMI  = data.aws_ami.vault_server_ami.id
  IAM_POLICY_DOCUMENTS = [data.aws_iam_policy_document.vault_server]
  SUBNET     = var.SUBNET
  VPC_SG_IDS = var.VPC_SG_IDS
  PUBLIC_IP = true
  KEY = var.KEY

  USER_DATA = templatefile("./modules/vault-cluster/scripts/vault-setup.tpl", {
      VAULT_LICENSE = var.VAULT_LICENSE,
      AWS_REGION    = var.REGION
      KMS_KEY       = aws_kms_key.vault.id
      CONSUL_HTTP_TOKEN = var.CONSUL_HTTP_TOKEN
    })

  TAGS = {
    consulAutoJoin = "client"
    owner          = "cmelgreen"
  }
}

data "aws_iam_policy_document" "vault_server" {
  statement {
    sid    = "VaultAWSAuthMethod"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "vault" {}

resource "aws_kms_alias" "vault" {
  name          = "alias/cmelgreen-vault-test-kms"
  target_key_id = aws_kms_key.vault.key_id
}