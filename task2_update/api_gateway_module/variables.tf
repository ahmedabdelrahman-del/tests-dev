variable "project_name" {
  type        = string
  description = "Prefix used for naming resources."
  default     = "cognito-throttle-lab"
}
variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into."
  default     = "us-east-1"
}
variable "api_stage_name" {
  type        = string
  description = "API Gateway stage name."
  default     = "dev"
}

variable "enable_api_key" {
  type        = bool
  description = "Require x-api-key on POST /oauth2/token and create a usage plan."
  default     = true
}

variable "token_rps" {
  type        = number
  description = "Steady-state requests per second allowed for the token endpoint."
  default     = 2
}

variable "token_burst" {
  type        = number
  description = "Burst capacity for the token endpoint."
  default     = 5
}

variable "usage_plan_rps" {
  type        = number
  description = "Per-client (per API key) steady-state RPS."
  default     = 1
}

variable "usage_plan_burst" {
  type        = number
  description = "Per-client (per API key) burst capacity."
  default     = 2
}

variable "usage_plan_quota_per_day" {
  type        = number
  description = "Per-client daily quota (requests/day) enforced by usage plan."
  default     = 3
}
variable "lambda_invoke_arn" {
  type        = string
  description = "Lambda function invoke ARN for API Gateway integration."
}