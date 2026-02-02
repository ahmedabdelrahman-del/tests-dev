# Thid output for WAF 
output "web_acl_arn" {
  value       = aws_wafv2_web_acl.this.arn
  description = "ARN of the WAF Web ACL"
}

output "web_acl_id" {
  value       = aws_wafv2_web_acl.this.id
  description = "ID of the WAF Web ACL"
}