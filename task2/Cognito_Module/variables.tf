variable "name" {
  description = "Base name for Cognito resources"
  type        = string
}

variable "region" {
  description = "AWS region (used to construct some URLs)"
  type        = string
}

variable "domain_prefix" {
  description = "Cognito hosted domain prefix (must be globally unique within region)"
  type        = string
}

variable "resource_server_identifier" {
  description = "Identifier for resource server (acts like the audience namespace for scopes)"
  type        = string
  default     = "https://api.example.local"
}

variable "scopes" {
  description = "List of OAuth scopes to create, e.g. [\"orders.read\", \"orders.write\"]"
  type        = list(string)
  default     = ["orders.read", "orders.write"]
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
