resource "aws_iam_policy" "execution_role_custom_policy" {
  name   = "MyAgentCoreExecutionRoleCustomPolicy"
  policy = file("${path.module}/MyAgentCoreExecutionRoleCustomPolicy.txt")
}
