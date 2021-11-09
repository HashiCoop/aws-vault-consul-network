data "aws_ami" "app_server_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["cmelgreen-vault-consul-base"]
  }

  owners = ["self"]
}

module "app_server" {
  source = "../ec2"

  NAME = "cmelgreen-test-app"
  AMI  = data.aws_ami.app_server_ami.id
  USER_DATA = file("./modules/app-stack/scripts/app-setup.sh")

  KEY = var.KEY

  IAM_POLICY_DOCUMENTS = [data.aws_iam_policy_document.app_server]

  PUBLIC_IP  = true
  SUBNET     = var.SUBNET
  VPC_SG_IDS = var.VPC_SG_IDS
}

data "aws_iam_policy_document" "app_server" {
  statement {
    sid    = "ConsulAutoJoin"
    effect = "Allow"
    actions = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_db_instance" "rds" {
  username                  = var.DB_USERNAME
  password                  = var.DB_PASSWORD
  final_snapshot_identifier = "cmelgreen-test-db-snapshot"
  skip_final_snapshot       = true
  allocated_storage         = 5
  storage_type              = "gp2"
  instance_class            = "db.t3.micro"
  engine                    = "postgres"
  publicly_accessible       = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = var.VPC_SG_IDS
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  subnet_ids = [
    var.SUBNET,
    var.BACKUP_SUBNET
  ]
}

module "external_services_server" {
  source = "../ec2"

  NAME = "cmelgreen-external-services-node"
  AMI  = data.aws_ami.app_server_ami.id
  USER_DATA = templatefile("./modules/app-stack/scripts/external-services-setup.tpl", {
    RDS_ADDRESS = aws_db_instance.rds.address 
    RDS_ENDPOINT = aws_db_instance.rds.endpoint 
  })

  IAM_POLICY_DOCUMENTS = [data.aws_iam_policy_document.external_services_server]

  KEY = var.KEY

  PUBLIC_IP  = true
  SUBNET     = var.SUBNET
  VPC_SG_IDS = var.VPC_SG_IDS
}

data "aws_iam_policy_document" "external_services_server" {
  statement {
    sid    = "ConsulAutoJoin"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }
}