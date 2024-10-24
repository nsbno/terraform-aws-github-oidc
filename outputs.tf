output "role_arn" {
  value = aws_iam_role.oidc_assume_role.arn
}

output "role_name" {
  value = aws_iam_role.oidc_assume_role.name
}
