variable "lambda_function_name" { type = string }
variable "api_gw_rest_api_name" { type = string } # optional if you want API Gateway alarms
variable "stage_name" {
  type    = string
  default = "dev"
}

# Email for notifications
variable "alarm_email" {
  type = string
}

# Thresholds (dev defaults)
variable "auth_failed_threshold_5m" {
  type    = number
  default = 20
} # 20 failures / 5 min

variable "lambda_errors_threshold_5m" {
  type    = number
  default = 5
}

variable "lambda_throttles_threshold_5m" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
