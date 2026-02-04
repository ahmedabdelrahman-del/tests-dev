# Random suffix to avoid name collisions between environments
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  # Use a unique name prefix for all resources
  name_prefix = "${var.project_name}-${random_string.suffix.result}"

  # Cognito domain prefixes must be DNS-compatible (letters/numbers/hyphens)
  # Remove reserved words like "cognito" from domain prefix
  domain_prefix = replace(
    replace(lower(local.name_prefix), "cognito-", ""),
    "_", "-"
  )
}

# ---------------------------------------------------------
# Cognito User Pool
# ---------------------------------------------------------
# This is the core container that hosts OAuth clients, tokens, and (optionally) users.
resource "aws_cognito_user_pool" "this" {
  name = local.name_prefix
  # Valid values: LITE, ESSENTIALS, PLUS
  user_pool_tier = var.user_pool_tier


  # Automatically verify email addresses
  auto_verified_attributes = ["email"]

  # Use email as the username
  username_attributes = ["email"]

  # Password complexity rules (useful for interactive/login testing later)
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  # Account recovery will rely on verified email
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

# ---------------------------------------------------------
# Cognito Resource Server + OAuth scopes (custom API scopes)
# ---------------------------------------------------------
# Defines custom OAuth scopes that App Clients can request.
resource "aws_cognito_resource_server" "api" {
  user_pool_id = aws_cognito_user_pool.this.id

  # Identifier is a logical namespace used when requesting scopes
  identifier = "https://api.${local.domain_prefix}.local"
  name       = "lab-api"

  scope {
    scope_name        = "tokens.read"
    scope_description = "Read token-related info"
  }

  scope {
    scope_name        = "tokens.write"
    scope_description = "Write token-related actions"
  }
}

# ---------------------------------------------------------
# Cognito Hosted UI Domain (Cognito-managed)
# ---------------------------------------------------------
# Required for OAuth endpoints like /oauth2/token and /oauth2/authorize.
# This uses a Cognito-managed domain prefix (no custom ACM certificate required).
resource "aws_cognito_user_pool_domain" "this" {
  domain       = local.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

# ---------------------------------------------------------
# App Client #1: Machine-to-machine (client_credentials)
# ---------------------------------------------------------
# Intended for service-to-service auth and token issuance via client_credentials.
resource "aws_cognito_user_pool_client" "m2m" {
  name         = "${local.name_prefix}-m2m"
  user_pool_id = aws_cognito_user_pool.this.id

  # Generate a client secret for confidential clients
  generate_secret = true

  # Enable OAuth for this client
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]

  # Allowed scopes this client may request
  allowed_oauth_scopes = [
    "${aws_cognito_resource_server.api.identifier}/tokens.read",
    "${aws_cognito_resource_server.api.identifier}/tokens.write"
  ]

  # Callback/logout URLs are not used by client_credentials, but Cognito/Terraform
  # can still require these fields when OAuth is enabled.
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  # Avoid leaking whether users exist during auth failures
  prevent_user_existence_errors = "ENABLED"
}

# ---------------------------------------------------------
# App Client #2: Interactive login (authorization_code)
# ---------------------------------------------------------
# Intended for browser-based auth (Hosted UI) using authorization_code.
resource "aws_cognito_user_pool_client" "interactive" {
  name         = "${local.name_prefix}-interactive"
  user_pool_id = aws_cognito_user_pool.this.id

  # Public client, no secret generated
  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]

  # Standard OIDC scopes + custom API scope
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile",
    "${aws_cognito_resource_server.api.identifier}/tokens.read"
  ]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  # Enable common authentication flows for testing (optional)
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}
