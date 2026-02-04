data "archive_file" "token_broker_zip" {
  type        = "zip"
  source_file = "${path.module}/broker.py"
  output_path = "${path.module}/.terraform-build/token-broker.zip"
}
resource "aws_lambda_function" "token_broker" {
  function_name = "${var.project_name}-token-broker"
  role          = aws_iam_role.token_broker_lambda.arn

  runtime = "python3.12"
  handler = "broker.handler"

  filename         = data.archive_file.token_broker_zip.output_path
  source_code_hash = data.archive_file.token_broker_zip.output_base64sha256

  timeout     = 15
  memory_size = 256

  environment {
    variables = {
      SSM_COGNITO_TOKEN_URL_PARAM     = var.broker_parameter_names.cognito_token_url
      SSM_COGNITO_CLIENT_ID_PARAM     = var.broker_parameter_names.cognito_client_id
      SSM_COGNITO_CLIENT_SECRET_PARAM = var.broker_parameter_names.cognito_client_secret
      SSM_ALLOWED_SCOPES_PARAM        = var.broker_parameter_names.allowed_scopes
    }
  }
    tags = {
    owner   = "Ahmed Abdelrahman"
    system  = "token-broker"
    purpose = "lambda-token-broker"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_read_ssm_params
  ]
}
