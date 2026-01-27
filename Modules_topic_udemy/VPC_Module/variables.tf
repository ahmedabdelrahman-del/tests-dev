  variable "aws_region"{
    description = "The AWS region to deploy resources"
    type        = string
    default = "us-east-1"
  }

variable "vpc_config"{
    type = object({
      name = string 
      cidr = string
    })
      validation {
    condition = can(cidrnetmask(var.vpc_config.cidr))
    error_message = "The cidr must contain valid cidr block"
  }
}
variable "subnet_config"{
    type = map(object({
      name = string 
      cidr = string
      az  = optional(string)
      public = optional(bool, false)
    }))
      validation {
    condition = alltrue([for s in values(var.subnet_config) : can(cidrnetmask(s.cidr))])
    error_message = "All subnet cidr blocks must be valid cidr blocks"
  }
}