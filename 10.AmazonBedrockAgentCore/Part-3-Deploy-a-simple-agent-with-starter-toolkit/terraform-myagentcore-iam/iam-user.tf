data "aws_iam_user" "existing_user" {
  user_name = "Terraform"
}

resource "aws_iam_user_policy_attachment" "cloudwatch_logs" {
  user       = data.aws_iam_user.existing_user.user_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_user_policy_attachment" "bedrock_fullaccess" {
  user       = data.aws_iam_user.existing_user.user_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

resource "aws_iam_user_policy" "myagent_inline_policy" {
  name   = "MyAgentCoreUserPolicy"
  user   = data.aws_iam_user.existing_user.user_name
  policy = file("${path.module}/MyAgentCoreUserPolicy.txt")
}