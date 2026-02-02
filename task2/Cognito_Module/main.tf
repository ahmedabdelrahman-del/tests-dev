# Create user Pool Even with zero users, it can still mint tokens for client_credentials
resource "aws_cognito_user_pool" "this" {
  name = "${var.name}-user-pool"

  # For service-to-service you don’t need signup flows.
  # This pool mainly exists as the OAuth token issuer.

  tags = var.tags
}
# Create a Resource Service + Scope this is needed to give least privillage permission between each service 
resource "aws_cognito_resource_server" "this" {
  user_pool_id = aws_cognito_user_pool.this.id
  identifier   = var.resource_server_identifier
  name         = "${var.name}-resource-server"

  dynamic "scope" {
    for_each = toset(var.scopes)
    content {
      scope_name        = scope.value
      scope_description = "Scope ${scope.value}"
    }
  }
}
# Create App Client
resource "aws_cognito_user_pool_client" "service_client" {
  name         = "${var.name}-service-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # This is critical for service-to-service:
  generate_secret = true

  # Turn on OAuth for this client
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]

  # Scopes this client is allowed to request
  allowed_oauth_scopes = [
    for s in var.scopes : "${aws_cognito_resource_server.this.identifier}/${s}"
  ]

  supported_identity_providers = ["COGNITO"]

  # Safe default: don’t reveal if a user exists (more relevant for user auth, still a good baseline)
  prevent_user_existence_errors = "ENABLED"
}
# Create a cognito Domain
resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}
# Store the client secret in Secrets Manager
resource "aws_secretsmanager_secret" "cognito_client_secret" {
  name        = "${var.name}-cognito-client-secret"
  description = "Client secret for Cognito app client used by token-broker Lambda"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "cognito_client_secret" {
  secret_id     = aws_secretsmanager_secret.cognito_client_secret.id
  secret_string = aws_cognito_user_pool_client.service_client.client_secret
}
