resource "aws_apigatewayv2_api" "viewcounter" {
  name          = "cloud-resume-view-counter"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "viewcounter" {
  api_id           = aws_apigatewayv2_api.viewcounter.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Cloud Resume Challenge View Counter Lambda"
  integration_method     = "ANY"
  integration_uri        = aws_lambda_function.viewcounter.invoke_arn
  payload_format_version = "2.0"  

  depends_on = [
    aws_lambda_function.viewcounter,
  ]
}

resource "aws_apigatewayv2_route" "viewcounter" {
  api_id    = aws_apigatewayv2_api.viewcounter.id
  route_key = "ANY /api/{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.viewcounter.id}"
}

resource "aws_apigatewayv2_deployment" "viewcounter" {
  api_id      = aws_apigatewayv2_api.viewcounter.id
  description = "Cloud Resume Challenge View Counter deployment"

  triggers = {
    redeployment = sha1(jsonencode(aws_apigatewayv2_api.viewcounter.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_lambda_function.viewcounter,
    aws_apigatewayv2_route.viewcounter,
    aws_lambda_permission.api_gateway_viewcounter
  ]
}

resource "aws_apigatewayv2_stage" "viewcounter" {
  deployment_id = aws_apigatewayv2_deployment.viewcounter.id
  api_id        = aws_apigatewayv2_api.viewcounter.id
  name          = "default"
}

resource "aws_apigatewayv2_domain_name" "viewcounter" {
  domain_name = "${local.api_subdomain}.${local.domain}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_domain.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "viewcounter" {
  api_id      = aws_apigatewayv2_api.viewcounter.id
  domain_name = aws_apigatewayv2_domain_name.viewcounter.id
  stage       = aws_apigatewayv2_stage.viewcounter.id
}