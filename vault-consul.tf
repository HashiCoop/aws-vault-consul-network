# data "aws_ami" "vault_server" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["cmelgreen-vault-consul-base"]
#   }

#   owners = ["self"]
# }

# module "server" {
#   source = "./modules/ec2"

#   NAME = "cmelgreen-test-vault"
#   TAGS = {
#     consulAutoJoin = "server"
#     owner          = "cmelgreen"
#   }
#   AMI  = data.aws_ami.vault_server.id

#   USER_DATA = join("\n", [
#     file("./scripts/consul-setup.sh"),
#     templatefile("./scripts/vault-setup.tpl",
#     {
#       VAULT_LICENSE = var.VAULT_LICENSE,
#       AWS_REGION    = var.REGION
#       KMS_KEY       = aws_kms_key.vault.id
#     })
#   ])

#   KEY = aws_key_pair.ssh_key.key_name

#   PUBLIC_IP  = true
#   SUBNET     = module.network.subnet.id
#   VPC_SG_IDS = [module.network.sg.id]
# }

# resource "aws_iam_policy" "vault_server" {
#   name   = "cmelgreen-vault-test"
#   policy = data.aws_iam_policy_document.vault_server.json
# }

# resource "aws_iam_role_policy_attachment" "vault_server" {
#   role       = module.server.iam_role.name
#   policy_arn = aws_iam_policy.vault_server.arn
# }

# data "aws_iam_policy_document" "vault_server" {
#   statement {
#     sid    = "ConsulAutoJoin"
#     effect = "Allow"

#     actions = ["ec2:DescribeInstances"]

#     resources = ["*"]
#   }

#   statement {
#     sid    = "VaultAWSAuthMethod"
#     effect = "Allow"
#     actions = [
#       "ec2:DescribeInstances",
#       "iam:GetInstanceProfile",
#       "iam:GetUser",
#       "iam:GetRole",
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "VaultKMSUnseal"
#     effect = "Allow"

#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:DescribeKey",
#     ]

#     resources = ["*"]
#   }
# }

# resource "aws_kms_key" "vault" {}

# resource "aws_kms_alias" "vault" {
#   name          = "alias/cmelgreen-vault-test-kms"
#   target_key_id = aws_kms_key.vault.key_id
# }
