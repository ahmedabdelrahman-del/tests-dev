variable "name_prefix" {
  type        = string
  description = "Prefix used for naming and SSM parameter path."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, stage, prod)."
  default     = "dev"
}

variable "cognito_token_url" {
  type        = string
  description = "Cognito /oauth2/token endpoint URL."
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito machine-to-machine App Client ID used by the broker."
}

variable "cognito_client_secret" {
  type        = string
  description = "Cognito machine-to-machine App Client secret used by the broker."
  sensitive   = true
}

variable "allowed_scopes" {
  type        = list(string)
  description = "List of OAuth scopes the broker is allowed to request."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to SSM parameters."
  default     = {}
}
variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into."
  default     = "us-east-1"
}