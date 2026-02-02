# package the lambda code 
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/${var.name}.zip"
}
# Creat IAM Rule for lambda in aws who is lambda 
resource "aws_iam_role" "lambda_role" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}
# IAM Policy Lambda  permissions (logs + secrets)
resource "aws_iam_policy" "lambda_policy"{
name = "${var.name}-policy"
policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Logging permissions
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      },

      # Read Cognito client secret from Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.cognito_client_secret_arn
      }
    ]
  })
}
# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
# Log Group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 14
  tags              = var.tags
}
# Create Lambda Function
resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = aws_iam_role.lambda_role.arn

  runtime = var.runtime
  handler = var.handler

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout      = var.timeout_seconds
  memory_size  = var.memory_mb

  environment {
    variables = {
      COGNITO_TOKEN_URL        = var.cognito_token_url
      COGNITO_CLIENT_ID        = var.cognito_client_id
      COGNITO_CLIENT_SECRET_ARN= var.cognito_client_secret_arn
      DEFAULT_SCOPE            = var.default_scope
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.attach
  ]

  tags = var.tags
}


