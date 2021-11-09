resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "backup_subnet" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       =  data.aws_availability_zones.available.names[1]
}

resource "aws_security_group" "sg" {
  name_prefix = var.NAME

  vpc_id = aws_vpc.vpc.id

  dynamic ingress {
    for_each = var.INGRESS_RULES

    content {
      from_port   = ingress.value.port
      to_port     = lookup(ingress.value, "to_port", ingress.value.port) 
      cidr_blocks = lookup(ingress.value, "cidr", ["0.0.0.0/0"])
      protocol    = lookup(ingress.value, "protocol", "tcp")
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_route_assosciation" {
  route_table_id = aws_route_table.public_rtb.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_route_table" "backup_rtb" {
    vpc_id          = aws_vpc.vpc.id

    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "backup_subnet" {
    subnet_id      = aws_subnet.backup_subnet.id
    route_table_id = aws_route_table.backup_rtb.id
}