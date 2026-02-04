# ---------------------------------------------------------
# IAM assume role policy for Lambda
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# Lambda execution role (token broker)
# ---------------------------------------------------------
resource "aws_iam_role" "token_broker_lambda" {
  name               = "${var.project_name}-token-broker-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    owner   = "Ahmed Abdelrahman"
    system  = "token-broker"
    purpose = "lambda-execution-role"
  }
}

# ---------------------------------------------------------
# Basic logging permissions (CloudWatch Logs)
# ---------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.token_broker_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------
# Least-privilege policy to read ONLY the required SSM parameters
# ---------------------------------------------------------
data "aws_iam_policy_document" "lambda_read_ssm_params" {
  statement {
    sid    = "ReadBrokerParameters"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]

    resources = [
      var.broker_parameter_arns.cognito_token_url,
      var.broker_parameter_arns.cognito_client_id,
      var.broker_parameter_arns.cognito_client_secret,
      var.broker_parameter_arns.allowed_scopes
    ]
  }
}

resource "aws_iam_policy" "lambda_read_ssm_params" {
  name        = "${var.project_name}-lambda-read-ssm-params"
  description = "Allow the token broker Lambda to read only the required SSM parameters."
  policy      = data.aws_iam_policy_document.lambda_read_ssm_params.json

  tags = {
    owner   = "Ahmed Abdelrahman"
    system  = "token-broker"
    purpose = "ssm-read-policy"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_read_ssm_params" {
  role       = aws_iam_role.token_broker_lambda.name
  policy_arn = aws_iam_policy.lambda_read_ssm_params.arn
}
