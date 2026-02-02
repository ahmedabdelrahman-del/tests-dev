output "api_id" {
  value       = aws_api_gateway_rest_api.this.id
  description = "API Gateway REST API ID"
}

output "invoke_url" {
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.this.stage_name}"
  description = "Invoke URL for this stage"
}

output "stage_arn" {
  value = "arn:aws:apigateway:${var.region}::/restapis/${aws_api_gateway_rest_api.this.id}/stages/${aws_api_gateway_stage.this.stage_name}"
  description = "Stage ARN (useful for WAF association input)"
}
output "stage_name" {
  value       = aws_api_gateway_stage.this.stage_name
  description = "The name of the deployed stage"
}