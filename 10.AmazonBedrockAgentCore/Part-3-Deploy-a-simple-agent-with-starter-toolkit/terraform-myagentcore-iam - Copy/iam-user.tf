resource "aws_iam_user" "myagent_user" {
  name = "MyAgentCoreUser"
  path = "/"
}

resource "aws_iam_user_policy_attachment" "cloudwatch_logs" {
  user       = aws_iam_user.myagent_user.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_user_policy_attachment" "bedrock_fullaccess" {
  user       = aws_iam_user.myagent_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

resource "aws_iam_access_key" "myagent_user_key" {
  user = aws_iam_user.myagent_user.name
}

resource "aws_iam_user_policy" "myagent_inline_policy" {
  name   = "MyAgentCoreUserPolicy"
  user   = aws_iam_user.myagent_user.name
  policy = file("${path.module}/MyAgentCoreUserPolicy.txt")
}