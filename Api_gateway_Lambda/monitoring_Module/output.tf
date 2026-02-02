output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value = [
    aws_cloudwatch_metric_alarm.auth_failed_spike.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name
  ]
}
