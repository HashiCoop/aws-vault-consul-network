# module "app_server" {
#   source = "./modules/ec2"

#   NAME = "cmelgreen-test-app"
#   AMI  = data.aws_ami.vault_server.id
#   USER_DATA = file("./scripts/app-setup.sh")

#   KEY = aws_key_pair.ssh_key.key_name

#   PUBLIC_IP  = true
#   SUBNET     = module.network.subnet.id
#   VPC_SG_IDS = [module.network.sg.id]
# }

# resource "aws_iam_policy" "app_server" {
#   name   = "cmelgreen-app-test"
#   policy = data.aws_iam_policy_document.app_server.json
# }

# resource "aws_iam_role_policy_attachment" "app_server" {
#   role       = module.app_server.iam_role.name
#   policy_arn = aws_iam_policy.app_server.arn
# }

# data "aws_iam_policy_document" "app_server" {
#   statement {
#     sid    = "ConsulAutoJoin"
#     effect = "Allow"

#     actions = ["ec2:DescribeInstances"]

#     resources = ["*"]
#   }
# }