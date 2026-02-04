output "token_broker_lambda_role_arn" {
  value       = aws_iam_role.token_broker_lambda.arn
  description = "IAM role ARN for the token broker Lambda."
}
output "token_broker_lambda_name" {
  value       = aws_lambda_function.token_broker.function_name
  description = "Deployed token broker Lambda function name."
}

output "token_broker_lambda_arn" {
  value       = aws_lambda_function.token_broker.arn
  description = "Deployed token broker Lambda function ARN."
}
output "token_broker_lambda_invoke_arn" {
  value       = aws_lambda_function.token_broker.invoke_arn
  description = "Lambda function invoke ARN for API Gateway integration."
}