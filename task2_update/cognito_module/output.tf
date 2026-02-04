output "user_pool_id" {
  description = "Cognito User Pool ID."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_domain_prefix" {
  description = "Cognito domain prefix (Cognito-managed)."
  value       = aws_cognito_user_pool_domain.this.domain
}

output "cognito_token_url" {
  description = "OAuth token endpoint URL."
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"
}

output "cognito_authorize_url" {
  description = "OAuth authorize endpoint URL (for interactive flows)."
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize"
}

output "resource_server_identifier" {
  description = "Resource server identifier used to build custom scopes."
  value       = aws_cognito_resource_server.api.identifier
}

output "m2m_client_id" {
  description = "App client ID for machine-to-machine client."
  value       = aws_cognito_user_pool_client.m2m.id
}

output "m2m_client_secret" {
  description = "App client secret for machine-to-machine client."
  value       = aws_cognito_user_pool_client.m2m.client_secret
  sensitive   = true
}

output "interactive_client_id" {
  description = "App client ID for interactive authorization_code client."
  value       = aws_cognito_user_pool_client.interactive.id
}
output "user_pool_tier" {
  description = "Cognito user pool feature plan / tier."
  value       = var.user_pool_tier
}
