output "public_ip" {
    value = aws_instance.server.public_ip
}

output "iam_role" {
    value = aws_iam_role.iam_role
}