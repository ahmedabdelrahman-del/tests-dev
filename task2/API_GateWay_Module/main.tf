# Fetch the current AWS account ID (used for Lambda permission ARNs)
data "aws_caller_identity" "current" {}

# Create the API Gateway REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.name}-rest-api"
  description = "REST API for ${var.name}"
  tags        = var.tags
}

# Create the /token resource under the API root
resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "token"
}

# Create the POST method for the /token endpoint
resource "aws_api_gateway_method" "post_token" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integrate the POST /token method with the Lambda function (AWS_PROXY)
resource "aws_api_gateway_integration" "lambda_token" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.post_token.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Create a deployment snapshot of the API configuration
# Triggers ensure a new deployment happens when routes/integrations change
resource "aws_api_gateway_deployment" "this" {
  depends_on  = [aws_api_gateway_integration.lambda_token]
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeploy = sha1(jsonencode({
      resource_id = aws_api_gateway_resource.token.id
      method_id   = aws_api_gateway_method.post_token.id
      integ_id    = aws_api_gateway_integration.lambda_token.id
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create the API Gateway stage (e.g., "prod") using the deployment
resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.this.id
  tags          = var.tags
}

# Configure throttling limits for the POST /token method at the stage level
resource "aws_api_gateway_method_settings" "token_post" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "token/POST"

  settings {
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
  }
}

# Allow API Gateway to invoke the Lambda function for this REST API and route
resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/POST/token"
}
