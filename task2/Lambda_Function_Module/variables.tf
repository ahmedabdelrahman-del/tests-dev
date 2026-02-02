variable "name" {
  description = "Base name for Lambda resources"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "handler" {
  description = "Lambda handler entrypoint"
  type        = string
  default     = "index.handler"
}

variable "cognito_token_url" {
  description = "Cognito token endpoint URL, e.g. https://<domain>/oauth2/token"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID used for client_credentials"
  type        = string
}

variable "cognito_client_secret_arn" {
  description = "ARN of Secrets Manager secret containing the Cognito App Client secret"
  type        = string
}

variable "default_scope" {
  description = "Default OAuth scope to request (optional)"
  type        = string
  default     = ""
}

variable "timeout_seconds" {
  description = "Lambda timeout"
  type        = number
  default     = 10
}

variable "memory_mb" {
  description = "Lambda memory"
  type        = number
  default     = 256
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
