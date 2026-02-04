output "user_pool_id" {
  description = "Cognito User Pool ID."
  value       = module.cognito_module.user_pool_id
}

output "user_pool_domain_prefix" {
  description = "Cognito domain prefix (Cognito-managed)."
  value       = module.cognito_module.user_pool_domain_prefix
}

output "cognito_token_url" {
  description = "OAuth token endpoint URL."
  value       = module.cognito_module.cognito_token_url
}

output "cognito_authorize_url" {
  description = "OAuth authorize endpoint URL (for interactive flows)."
  value       = module.cognito_module.cognito_authorize_url
}

output "resource_server_identifier" {
  description = "Resource server identifier used to build custom scopes."
  value       = module.cognito_module.resource_server_identifier
}

output "m2m_client_id" {
  description = "App client ID for machine-to-machine client."
  value       = module.security_string_module.parameter_names.cognito_client_id
}

output "m2m_client_secret" {
  description = "App client secret for machine-to-machine client."
  value       = module.security_string_module.parameter_names.cognito_client_secret
  sensitive   = true
}

output "interactive_client_id" {
  description = "App client ID for interactive authorization_code client."
  value       = module.cognito_module.interactive_client_id
}
output "feature_plan" {
  description = "Cognito user pool feature plan / tier."
  value       = module.cognito_module.user_pool_tier
}
output "base_path" {
  description = "Base SSM path where broker parameters are stored."
  value       = module.security_string_module.base_path
}

output "parameter_names" {
  description = "Names of the SSM parameters created by this module."
  value = {
    cognito_token_url      = module.security_string_module.parameter_names.cognito_token_url
    cognito_client_id      = module.security_string_module.parameter_names.cognito_client_id
    cognito_client_secret  = module.security_string_module.parameter_names.cognito_client_secret
    allowed_scopes         = module.security_string_module.parameter_names.allowed_scopes
  }
}

output "parameter_arns" {
  description = "ARNs of the SSM parameters created by this module."
  value = {
    cognito_token_url      = module.security_string_module.parameter_arns.cognito_token_url
    cognito_client_id      = module.security_string_module.parameter_arns.cognito_client_id
    cognito_client_secret  = module.security_string_module.parameter_arns.cognito_client_secret
    allowed_scopes         = module.security_string_module.parameter_arns.allowed_scopes
  }
}


output "token_broker_lambda_role_arn" {
  value       = module.lambda_module.token_broker_lambda_role_arn
  description = "IAM role ARN for the token broker Lambda."
}
output "token_broker_lambda_name" {
  value       = module.lambda_module.token_broker_lambda_name
  description = "Deployed token broker Lambda function name."
}

output "token_broker_lambda_arn" {
  value       = module.lambda_module.token_broker_lambda_arn
  description = "Deployed token broker Lambda function ARN."
}
output "token_broker_invoke_url" {
  value       = module.api_gateway_module.token_broker_invoke_url
  }
output "api_execution_arn" {
  value       = module.api_gateway_module.api_execution_arn
  description = "API Gateway execution ARN."
}