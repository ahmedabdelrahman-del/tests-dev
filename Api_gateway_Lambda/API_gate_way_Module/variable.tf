variable "api_name" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "dev"
}

variable "lambda_invoke_arn" { type = string } # من output lambda.invoke_arn
variable "lambda_name"       { type = string } # من output lambda.function_name

# throttling (مبدئيًا للـ dev)
variable "throttle_rate" {
  type    = number
  default = 50
}

variable "throttle_burst" {
  type    = number
  default = 100
}

variable "tags" {
  type    = map(string)
  default = {}
}
