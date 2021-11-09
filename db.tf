# resource "aws_db_instance" "rds" {
#   username                  = var.DB_USERNAME
#   password                  = var.DB_PASSWORD
#   final_snapshot_identifier = "cmelgreen-test-db-snapshot"
#   skip_final_snapshot       = true
#   allocated_storage         = 5
#   storage_type              = "gp2"
#   instance_class            = "db.t3.micro"
#   engine                    = "postgres"
#   publicly_accessible       = true

#   db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
#   vpc_security_group_ids = [module.network.sg.id]
# }

# resource "aws_db_subnet_group" "rds_subnet_group" {
#   subnet_ids = [
#     module.network.subnet.id,
#     module.network.backup_subnet.id
#   ]
# }

# module "external_services_server" {
#   source = "./modules/ec2"

#   NAME = "cmelgreen-external-services-node"
#   AMI  = data.aws_ami.vault_server.id
#   USER_DATA = templatefile("./scripts/external-services-setup.sh", {
#     RDS_ADDRESS = aws_db_instance.rds.address 
#     RDS_ENDPOINT = aws_db_instance.rds.endpoint 
#   })

#   KEY = aws_key_pair.ssh_key.key_name

#   PUBLIC_IP  = true
#   SUBNET     = module.network.subnet.id
#   VPC_SG_IDS = [module.network.sg.id]
# }

# resource "aws_iam_policy" "external_services_server" {
#   name   = "cmelgreen-external_services-test"
#   policy = data.aws_iam_policy_document.external_services_server.json
# }

# resource "aws_iam_role_policy_attachment" "external_services_server" {
#   role       = module.external_services_server.iam_role.name
#   policy_arn = aws_iam_policy.external_services_server.arn
# }

# data "aws_iam_policy_document" "external_services_server" {
#   statement {
#     sid    = "ConsulAutoJoin"
#     effect = "Allow"

#     actions = ["ec2:DescribeInstances"]

#     resources = ["*"]
#   }
# }