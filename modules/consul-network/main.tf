data "aws_ami" "consul_server_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["cmelgreen-vault-consul-base"]
  }

  owners = ["self"]
}

module "consul_server" {
  source = "../ec2"

  NAME = "cmelgreen-test-consul"
  TAGS = {
    consulAutoJoin = "server"
    owner          = "cmelgreen"
  }
  KEY = var.KEY

  AMI  = data.aws_ami.consul_server_ami.id
  USER_DATA = file("./modules/consul-network/scripts/consul-setup.sh")

  IAM_POLICY_DOCUMENTS = [data.aws_iam_policy_document.consul_server]

  SUBNET     = module.network.subnet.id
  VPC_SG_IDS = [module.network.sg.id]
  PUBLIC_IP = true
}

data "aws_iam_policy_document" "consul_server" {
  statement {
    sid    = "ConsulAutoJoin"
    effect = "Allow"
    actions = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

module "network" {
  source = "../network-base"

  NAME = "cmelgreen-test-"

  INGRESS_RULES = [
    {port="22"},
    {port="80"},
    {port="433"},
    {port="5432"},
    {port="8200"},
    {port="8300", to_port="8302"},
    {port="8301", to_port="8302", protocl="udp"},
    {port="21000", to_port="21255"},
    {port="8500"},
    {port="8600"},
    {port="8600", protocol="udp"}
  ]
}