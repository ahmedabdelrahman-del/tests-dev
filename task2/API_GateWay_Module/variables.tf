# Api GateWay Variables
variable "name" {
  description = "Base name for API Gateway resources"
  type        = string
}

variable "stage_name" {
  description = "Stage name, e.g., dev, prod"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the token-broker Lambda"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the token-broker Lambda (used for permissions)"
  type        = string
}

variable "throttle_rate_limit" {
  description = "Steady-state requests per second (API Gateway throttling)"
  type        = number
  default     = 2
}

variable "throttle_burst_limit" {
  description = "Burst requests allowed (API Gateway throttling)"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
