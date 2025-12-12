# IAM role for Lambda execution
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "viewcounter_lambda" {
  name               = "view_counter_lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Common dependencies layer
resource "aws_lambda_layer_version" "viewcounter_dependencies" {
  filename    = "${path.root}/dependencies.zip"
  layer_name  = "viewcounter_dependencies_layer"
  description = "Common dependencies for viewcounter Lambda functions"

  compatible_runtimes      = [local.python_version]
  compatible_architectures = ["x86_64", "arm64"]
}

resource "aws_lambda_function" "viewcounter" {
  filename      = "${path.root}/lambda_package.zip"
  function_name = "view-counter"
  role          = aws_iam_role.viewcounter_lambda.arn
  handler       = "view_counter.main.handler"
  runtime       = local.python_version

  timeout = 10

  layers = [aws_lambda_layer_version.viewcounter_dependencies.arn]
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway_viewcounter" {
  statement_id  = "AllowViewCounterAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "view-counter"
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_apigatewayv2_api.viewcounter.execution_arn}/*"
}