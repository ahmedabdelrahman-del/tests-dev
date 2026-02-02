resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "extra" {
  name = "${var.role_name}-extra"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DynamoRateLimit",
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Resource = var.ratelimit_table_arn
      },
      {
        Sid    = "CognitoAuthCalls",
        Effect = "Allow",
        Action = [
          "cognito-idp:InitiateAuth",
          "cognito-idp:RespondToAuthChallenge"
        ],
        Resource = var.user_pool_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "extra_attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.extra.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn

  runtime = var.runtime
  handler = var.handler

  filename         = var.package_path
  source_code_hash = filebase64sha256(var.package_path)

  timeout     = var.timeout_seconds
  memory_size = var.memory_mb

  # Reserved concurrency is optional - set to null by default
  reserved_concurrent_executions = var.reserved_concurrency

  environment {
    variables = {
      RATELIMIT_TABLE = var.ratelimit_table_name

      # Cognito
      USER_POOL_ID = var.user_pool_id
      CLIENT_ID    = var.app_client_id

      # Rate limit config (example defaults)
      WINDOW_SECONDS = tostring(var.window_seconds)

      LOGIN_USER_MAX_PER_WINDOW   = tostring(var.login_user_max_per_window)
      LOGIN_IP_MAX_PER_WINDOW     = tostring(var.login_ip_max_per_window)
      REFRESH_USER_MAX_PER_WINDOW = tostring(var.refresh_user_max_per_window)
      REFRESH_IP_MAX_PER_WINDOW   = tostring(var.refresh_ip_max_per_window)

      LOG_LEVEL = var.log_level
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.basic_logs,
    aws_iam_role_policy_attachment.extra_attach
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  count         = var.api_gateway_execution_arn != "" ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
