variable "table_name" { type = string }

variable "enable_point_in_time_recovery" {
  type    = bool
  default = true
  description = "Enable point-in-time recovery for the table"
}

variable "deletion_protection" {
  type    = bool
  default = false
  description = "Enable deletion protection for production tables"
}

variable "enable_streams" {
  type    = bool
  default = false
  description = "Enable DynamoDB streams for monitoring throttle events"
}

variable "tags" { 
  type = map(string)
  default = {} 
}
