output "vpc" {
  value = aws_vpc.vpc
}

output "subnet" {
  value = aws_subnet.public_subnet
}

output "backup_subnet" {
  value = aws_subnet.backup_subnet
}

output "sg" {
  value = aws_security_group.sg
}