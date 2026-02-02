resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

# ---------- Resources ----------
resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "token"
}

resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.token.id
  path_part   = "login"
}

resource "aws_api_gateway_resource" "refresh" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.token.id
  path_part   = "refresh"
}

resource "aws_api_gateway_resource" "mfa" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.token.id
  path_part   = "mfa"
}

# ---------- Methods + Proxy Integration ----------
locals {
  endpoints = {
    login   = aws_api_gateway_resource.login.id
    refresh = aws_api_gateway_resource.refresh.id
    mfa     = aws_api_gateway_resource.mfa.id
  }
}

resource "aws_api_gateway_method" "post" {
  for_each      = local.endpoints
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value
  http_method   = "POST"
  authorization = "NONE"
}

# CORS OPTIONS method for each endpoint
resource "aws_api_gateway_method" "options" {
  for_each      = local.endpoints
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each      = local.endpoints
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value
  http_method   = aws_api_gateway_method.options[each.key].http_method
  type          = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each    = local.endpoints
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options" {
  for_each            = local.endpoints
  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = each.value
  http_method         = aws_api_gateway_method.options[each.key].http_method
  status_code         = aws_api_gateway_method_response.options[each.key].status_code
  selection_pattern   = ""

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options]
}

resource "aws_api_gateway_integration" "lambda_proxy" {
  for_each               = local.endpoints
  rest_api_id            = aws_api_gateway_rest_api.this.id
  resource_id            = each.value
  http_method            = aws_api_gateway_method.post[each.key].http_method
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.lambda_invoke_arn
}

# ---------- Lambda permission for API Gateway ----------
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"

  # يسمح لكل الميثودز/المسارات داخل الـ API
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# ---------- Deployment + Stage ----------
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # مهم عشان deployment يتحدث لما تغيّر resources/methods/integration
  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_resource.login.id,
      aws_api_gateway_resource.refresh.id,
      aws_api_gateway_resource.mfa.id,
      aws_api_gateway_method.post["login"].id,
      aws_api_gateway_method.post["refresh"].id,
      aws_api_gateway_method.post["mfa"].id,
      aws_api_gateway_method.options["login"].id,
      aws_api_gateway_method.options["refresh"].id,
      aws_api_gateway_method.options["mfa"].id,
      aws_api_gateway_integration.lambda_proxy["login"].id,
      aws_api_gateway_integration.lambda_proxy["refresh"].id,
      aws_api_gateway_integration.lambda_proxy["mfa"].id,
      aws_api_gateway_integration.options["login"].id,
      aws_api_gateway_integration.options["refresh"].id,
      aws_api_gateway_integration.options["mfa"].id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.lambda_proxy, aws_api_gateway_integration_response.options]
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
  tags          = var.tags
}

# ---------- CloudWatch Logs Role for API Gateway ----------
resource "aws_iam_role" "apigw_cloudwatch" {
  name = "${var.api_name}-apigw-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "apigw_cloudwatch" {
  name = "${var.api_name}-apigw-cloudwatch-logs-policy"
  role = aws_iam_role.apigw_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Set CloudWatch Logs Role ARN in account settings
resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

# ---------- Throttling (Method Settings) ----------
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.throttle_rate
    throttling_burst_limit = var.throttle_burst
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = false
  }

  depends_on = [aws_api_gateway_account.this]
}
