variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Prefix used for naming resources."
  default     = "cognito-throttle-lab"
}

variable "callback_urls" {
  type        = list(string)
  description = "OAuth callback URLs used by interactive clients (authorization_code)."
  default     = ["https://example.com/callback"]
}

variable "logout_urls" {
  type        = list(string)
  description = "OAuth logout URLs used by interactive clients."
  default     = ["https://example.com/logout"]
}
variable "user_pool_tier" {
  type        = string
  description = "Cognito user pool feature plan / tier. Valid values: LITE, ESSENTIALS, PLUS."
  default     = "LITE"

  validation {
    condition     = contains(["LITE", "ESSENTIALS", "PLUS"], var.user_pool_tier)
    error_message = "user_pool_tier must be one of: LITE, ESSENTIALS, PLUS."
  }
}
