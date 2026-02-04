variable "project_name" {
  type        = string
  description = "Prefix used for naming resources."
  default     = "cognito-throttle-lab"
}
variable "broker_parameter_arns" {
  type = object({
    cognito_token_url     = string
    cognito_client_id     = string
    cognito_client_secret = string
    allowed_scopes        = string
  })
  description = "ARNs of SSM parameters for Cognito broker secrets."
}

variable "broker_parameter_names" {
  type = object({
    cognito_token_url     = string
    cognito_client_id     = string
    cognito_client_secret = string
    allowed_scopes        = string
  })
  description = "Names of SSM parameters for Cognito broker secrets."
}
