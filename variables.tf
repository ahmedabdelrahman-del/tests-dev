variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "token-broker-demo"
}

variable "stage_name" {
  type    = string
  default = "prod"
}

# Must be unique within the region
variable "cognito_domain_prefix" {
  type = string
}

variable "waf_rate_limit" {
  description = "Requests per 5 minutes per IP"
  type        = number
  default     = 200
}

variable "apigw_rate_limit" {
  description = "Requests per second (steady)"
  type        = number
  default     = 2
}

variable "apigw_burst_limit" {
  description = "Burst limit"
  type        = number
  default     = 4
}

variable "resource_server_identifier" {
  type    = string
  default = "https://api.example.local"
}

variable "scopes" {
  type    = list(string)
  default = ["orders.read", "orders.write"]
}

variable "allow_ip_cidrs" {
  type    = list(string)
  default = []
}

variable "block_ip_cidrs" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
