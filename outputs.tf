output "aws_region" {
  description = "AWS region being used"
  value       = var.aws_region
}

output "terraform_workspace" {
  description = "Terraform workspace"
  value       = terraform.workspace
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public subnet details"
  value       = module.vpc.public_subnet
}

output "private_subnets" {
  description = "Private subnet details"
  value       = module.vpc.private_subnet
}

#output "s3_bucket_endpoint" {
 # description = "end of the S3 bucket for static website hosting"
  #value       = "http://${module.s3_static_website.s3_bucket_name}.s3-website-${var.aws_region}.amazonaws.com"
  #}
