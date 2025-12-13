# IAM policy for CloudWatch Logs access
data "aws_iam_policy_document" "cloudwatch_role" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_access" {
  name = "viewcounter-cloudwatch-access"
  policy = data.aws_iam_policy_document.cloudwatch_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  policy_arn = aws_iam_policy.cloudwatch_access.arn
  role       = aws_iam_role.viewcounter_lambda.name
}

resource "aws_iam_role_policy_attachment" "apigateway_cloudwatch" {
  policy_arn = aws_iam_policy.cloudwatch_access.arn
  role       = aws_iam_role.viewcounter_apigateway.name
}

# IAM policy for DynamoDB access
data "aws_iam_policy_document" "dynamodb_role" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name = "viewcounter-dynamodb-access"
  policy = data.aws_iam_policy_document.dynamodb_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  policy_arn = aws_iam_policy.dynamodb_access.arn
  role       = aws_iam_role.viewcounter_lambda.name
}