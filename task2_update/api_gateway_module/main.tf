#Creates the API container in Amazon API Gateway where all routes, methods, and stages live.
resource "aws_api_gateway_rest_api" "token_broker" {
  name        = "${var.project_name}-token-broker-api"
  description = "REST API front door for the Lambda token broker."

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
#Creates the /oauth2 path segment.
resource "aws_api_gateway_resource" "oauth2" {
  rest_api_id = aws_api_gateway_rest_api.token_broker.id
  parent_id   = aws_api_gateway_rest_api.token_broker.root_resource_id
  path_part   = "oauth2"
}
#Creates /oauth2/token under /oauth2.
resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.token_broker.id
  parent_id   = aws_api_gateway_resource.oauth2.id
  path_part   = "token"
}
#Creates the POST method on /oauth2/token. Defines the HTTP entry point: POST on /oauth2/token. 
resource "aws_api_gateway_method" "post_token" {
  rest_api_id   = aws_api_gateway_rest_api.token_broker.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "POST"
  authorization = "NONE"
# this setting makes the API require an API key if enabled
  api_key_required = var.enable_api_key
  }
  # Integration: API Gateway → Lambda (proxy integration)
resource "aws_api_gateway_integration" "lambda_proxy" {
  rest_api_id = aws_api_gateway_rest_api.token_broker.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.post_token.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  # Lambda invoke URI
  uri                     = var.lambda_invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
}

# Permission for API Gateway to invoke the Lambda function. Allows only this API/method/path to invoke the Lambda. Without this, API Gateway calls fail.
# NOTE: This permission must be created in the root module or passed as a variable dependency
# to avoid circular references and maintain module independence.
# REST APIs require an explicit “deployment” for a stage. Creates a deployment artifact (a snapshot of your API configuration).
resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.token_broker.id
  # Ensure deployment happens after method+integration exist
  depends_on = [
    aws_api_gateway_method.post_token,
    aws_api_gateway_integration.lambda_proxy
  ]
}
# Creates a stage like dev and produces an invoke URL: https://{api-id}.execute-api.{region}.amazonaws.com/dev/oauth2/token
resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.token_broker.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = var.api_stage_name

  # Optional: enable metrics (no request/response body logging for token endpoints)
  xray_tracing_enabled = false
}
# Throttling settings for POST /oauth2/token method
#Applies throttling to the specific method:
#Rate limit = steady requests/second
#Burst limit = short spikes allowed
#If exceeded, API Gateway returns 429 Too Many Requests before invoking Lambda.
resource "aws_api_gateway_method_settings" "token_throttle" {
  rest_api_id = aws_api_gateway_rest_api.token_broker.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "${aws_api_gateway_resource.token.path_part}/${aws_api_gateway_method.post_token.http_method}"

  settings {
    throttling_rate_limit  = var.token_rps
    throttling_burst_limit = var.token_burst

    metrics_enabled = true

    # Disable logging to avoid CloudWatch Logs role requirement
    logging_level      = "OFF"
    data_trace_enabled = false
  }
}
#Creates an API key that callers pass via x-api-key: ....
resource "aws_api_gateway_api_key" "token_broker_key" {
  count = var.enable_api_key ? 1 : 0

  name        = "${var.project_name}-token-broker-api-key"
  description = "API key for accessing the token broker API."

  enabled = true
}

# Usage plan to associate the API key with the stage
#Enforces:
#per API key throttling (rate/burst)
#per API key daily quota (requests/day)
#Usage plan limits apply per API key, so clients don’t impact each other.
#When quota is hit → API Gateway blocks further calls (typically 429).
resource "aws_api_gateway_usage_plan" "token_plan" {
  count = var.enable_api_key ? 1 : 0

  name        = "${var.project_name}-token-usage-plan"
  description = "Usage plan for token endpoint throttling and quota."

  api_stages {
    api_id = aws_api_gateway_rest_api.token_broker.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  throttle_settings {
    rate_limit  = var.usage_plan_rps
    burst_limit = var.usage_plan_burst
  }

  quota_settings {
    limit  = var.usage_plan_quota_per_day
    period = "DAY"
  }
}
#Associates the API key with the usage plan (required for enforcement).
#Without this binding, per-key throttling/quota won’t apply.
resource "aws_api_gateway_usage_plan_key" "bind_key" {
  count = var.enable_api_key ? 1 : 0

  key_id        = aws_api_gateway_api_key.token_broker_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.token_plan[0].id
}








