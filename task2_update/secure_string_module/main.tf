locals {
  # A consistent hierarchical path makes access control easy.
  # Example: /cognito-throttle-lab/dev/broker/...
  base_path = "/${var.name_prefix}/${var.environment}/broker"

  default_tags = merge(var.tags, {
    module      = "ssm-secrets"
    environment = var.environment
  })
}

# ---------------------------------------------------------
# Token endpoint URL (non-secret but still stored centrally)
# ---------------------------------------------------------
resource "aws_ssm_parameter" "cognito_token_url" {
  name        = "${local.base_path}/cognito_token_url"
  description = "Cognito OAuth2 token endpoint URL used by the token broker."
  type        = "String"
  value       = var.cognito_token_url
  tags        = local.default_tags
}

# ---------------------------------------------------------
# Cognito M2M client_id (not secret, but treat as controlled config)
# ---------------------------------------------------------
resource "aws_ssm_parameter" "cognito_client_id" {
  name        = "${local.base_path}/cognito_client_id"
  description = "Cognito machine-to-machine app client_id used by the token broker."
  type        = "String"
  value       = var.cognito_client_id
  tags        = local.default_tags
}

# ---------------------------------------------------------
# Cognito M2M client_secret (secret)
# SecureString is encrypted at rest. If key_id is omitted,
# SSM uses the AWS-managed KMS key for Parameter Store (aws/ssm).
# ---------------------------------------------------------
resource "aws_ssm_parameter" "cognito_client_secret" {
  name        = "${local.base_path}/cognito_client_secret"
  description = "Cognito machine-to-machine app client_secret used by the token broker."
  type        = "SecureString"
  value       = var.cognito_client_secret
  tags        = local.default_tags
}

# ---------------------------------------------------------
# Allowed scopes (stored as JSON array for easy parsing)
# ---------------------------------------------------------
resource "aws_ssm_parameter" "allowed_scopes" {
  name        = "${local.base_path}/allowed_scopes"
  description = "JSON array of OAuth scopes allowed for the token broker."
  type        = "String"
  value       = jsonencode(var.allowed_scopes)
  tags        = local.default_tags
}
