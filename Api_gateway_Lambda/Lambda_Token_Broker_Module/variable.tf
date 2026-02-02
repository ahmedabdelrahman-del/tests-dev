variable "role_name"      { type = string }
variable "function_name"  { type = string }
variable "package_path"   { type = string }

variable "runtime" {
  type    = string
  default = "nodejs20.x"
}
variable "handler" {
  type    = string
  default = "index.handler"
}

variable "timeout_seconds" {
  type    = number
  default = 10
}
variable "memory_mb" {
  type    = number
  default = 256
}

variable "reserved_concurrency" {
  type    = number
  default = null
  description = "Reserved concurrent executions for Lambda (optional, default: unreserved)"
}

variable "log_retention_days" {
  type    = number
  default = 7
  description = "CloudWatch log retention in days"
}

variable "api_gateway_execution_arn" {
  type    = string
  default = ""
  description = "API Gateway execution ARN for Lambda invoke permission"
}

# DynamoDB limiter
variable "ratelimit_table_name" { type = string }
variable "ratelimit_table_arn"  { type = string }

# Cognito
variable "user_pool_id"  { type = string }
variable "user_pool_arn" { type = string }
variable "app_client_id" { type = string }

# Rate limiting defaults (good starting point)
variable "window_seconds" {
  type    = number
  default = 60
}

# /token/login
variable "login_user_max_per_window" {
  type    = number
  default = 5
}
variable "login_ip_max_per_window" {
  type    = number
  default = 30
}

# /token/refresh
variable "refresh_user_max_per_window" {
  type    = number
  default = 20
}
variable "refresh_ip_max_per_window" {
  type    = number
  default = 120
}

variable "log_level" {
  type    = string
  default = "INFO"
}

variable "tags" {
  type    = map(string)
  default = {}
}
