# IAM policy for CloudWatch Logs access
data "aws_iam_policy_document" "cloudwatch_role" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup", 
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_access" {
  name = "lambda-viewcounter-cloudwatch-access"
  policy = data.aws_iam_policy_document.cloudwatch_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  policy_arn = aws_iam_policy.cloudwatch_access.arn
  role       = aws_iam_role.viewcounter_lambda.name
}