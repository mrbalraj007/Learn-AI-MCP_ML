output "access_key_id" {
  value = aws_iam_access_key.myagent_user_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.myagent_user_key.secret
  sensitive = true
}

output "iam_user_name" {
  value = aws_iam_user.myagent_user.name
}

output "execution_role_arn" {
  value = aws_iam_role.execution_role.arn
}