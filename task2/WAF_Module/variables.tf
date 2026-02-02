variable "name" {
  description = "Base name for WAF resources"
  type        = string
}

variable "scope" {
  description = "WAF scope: REGIONAL for API Gateway, CLOUDFRONT for CloudFront"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT"
  }
}


variable "global_rate_limit" {
  description = "Max requests per 5-minute window per IP before blocking (global, all paths)"
  type        = number
  default     = 10000
}

variable "token_path_rate_limit" {
  description = "Max requests per 5-minute window per IP for /token path (stricter)"
  type        = number
  default     = 200
}

variable "allow_ip_cidrs" {
  description = "Optional allowlist CIDRs (trusted IP ranges)"
  type        = list(string)
  default     = []
}

variable "block_ip_cidrs" {
  description = "Optional blocklist CIDRs (known bad IP ranges)"
  type        = list(string)
  default     = []
}

variable "enable_logging" {
  description = "Enable WAF logging"
  type        = bool
  default     = false
}

variable "log_destination_arns" {
  description = "List of log destination ARNs (e.g., Kinesis Firehose). Required if enable_logging=true"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "target_resource_arn" {
  description = "ARN of the resource to protect (for API Gateway REST API: arn:aws:apigateway:{region}::/restapis/{rest_api_id}/stages/{stage_name})"
  type        = string
}
