output "user_pool_id" {
  value       = aws_cognito_user_pool.this.id
  description = "Cognito User Pool ID"
}

output "client_id" {
  value       = aws_cognito_user_pool_client.service_client.id
  description = "Cognito App Client ID"
}

output "client_secret_arn" {
  value       = aws_secretsmanager_secret.cognito_client_secret.arn
  description = "Secrets Manager ARN containing the client secret"
}

output "cognito_domain" {
  value       = aws_cognito_user_pool_domain.this.domain
  description = "Cognito domain prefix"
}

output "token_url" {
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${var.region}.amazoncognito.com/oauth2/token"
  description = "Full token endpoint URL for OAuth2 token requests"
}

output "allowed_scopes" {
  value       = [for s in var.scopes : "${aws_cognito_resource_server.this.identifier}/${s}"]
  description = "Full scope strings allowed for this app client"
}
