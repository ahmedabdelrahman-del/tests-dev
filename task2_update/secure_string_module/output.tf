output "base_path" {
  description = "Base SSM path where broker parameters are stored."
  value       = local.base_path
}

output "parameter_names" {
  description = "Names of the SSM parameters created by this module."
  value = {
    cognito_token_url      = aws_ssm_parameter.cognito_token_url.name
    cognito_client_id      = aws_ssm_parameter.cognito_client_id.name
    cognito_client_secret  = aws_ssm_parameter.cognito_client_secret.name
    allowed_scopes         = aws_ssm_parameter.allowed_scopes.name
  }
}

output "parameter_arns" {
  description = "ARNs of the SSM parameters created by this module."
  value = {
    cognito_token_url      = aws_ssm_parameter.cognito_token_url.arn
    cognito_client_id      = aws_ssm_parameter.cognito_client_id.arn
    cognito_client_secret  = aws_ssm_parameter.cognito_client_secret.arn
    allowed_scopes         = aws_ssm_parameter.allowed_scopes.arn
  }
}
