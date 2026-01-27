variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  }
variable "subnet_cidr" {
  description = "CIDR block for the Subnet"
  type        = string
  default     = "10.0.0.0/24"
  }