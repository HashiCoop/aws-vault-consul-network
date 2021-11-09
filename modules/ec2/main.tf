resource "aws_instance" "server" {
    ami                         = var.AMI != "" ? var.AMI : data.aws_ami.ubuntu.id
    instance_type               = var.INSTANCE_TYPE
    associate_public_ip_address = var.PUBLIC_IP

    iam_instance_profile        = aws_iam_instance_profile.iam_profile.name
    key_name = var.KEY
    user_data                   = var.USER_DATA

    subnet_id                   = var.SUBNET
    vpc_security_group_ids      = var.VPC_SG_IDS

    tags = merge({ Name = var.NAME }, var.TAGS)
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_iam_instance_profile" "iam_profile" {
    name                = join("_", [var.NAME, "server_iam_profile"])
    role                = aws_iam_role.iam_role.name
}

resource "aws_iam_role" "iam_role" {
    name                = join("_", [var.NAME, "server_iam_role"])
    assume_role_policy  = var.IAM_BASE_POLICY
}

resource "aws_iam_policy" "iam_policies_from_documents" {
  for_each = toset(var.IAM_POLICY_DOCUMENTS[*].json)
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "iam_policy_attachments" {
    for_each            = toset(var.IAM_POLICIES)

    policy_arn          = each.value
    role                = aws_iam_role.iam_role.name
}

resource "aws_iam_role_policy_attachment" "iam_policy_document_attachments" {
    for_each            = aws_iam_policy.iam_policies_from_documents

    policy_arn          = each.value.arn
    role                = aws_iam_role.iam_role.name
}
