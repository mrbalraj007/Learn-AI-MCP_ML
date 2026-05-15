data "aws_iam_policy_document" "execution_role_trust" {

  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com",
        "ecs-tasks.amazonaws.com",
        "bedrock-agentcore.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "MyAgentCoreExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.execution_role_trust.json
}

resource "aws_iam_role_policy_attachment" "attach_custom_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_role_custom_policy.arn
}