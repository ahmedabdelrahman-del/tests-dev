variable "name" { type = string }

# REST API Gateway stage ARN (we will pass it from root)
variable "apigw_stage_arn" { type = string }

# Rate-based: number of requests allowed per 5 minutes per IP
variable "ip_rate_limit_5m" {
  type    = number
  default = 2000
}

# Only protect /token* paths (recommended)
variable "protect_token_paths_only" {
  type    = bool
  default = true
}

# Enable AWS managed rules (optional)
variable "enable_managed_rules" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
