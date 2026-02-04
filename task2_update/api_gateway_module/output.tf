output "token_broker_invoke_url" {
  value       = "https://${aws_api_gateway_rest_api.token_broker.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.stage.stage_name}/oauth2/token"
  description = "Invoke URL for POST /oauth2/token."
}
output "api_execution_arn" {
  value       = aws_api_gateway_rest_api.token_broker.execution_arn
  description = "API Gateway execution ARN."
}