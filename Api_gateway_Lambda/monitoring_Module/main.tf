resource "aws_sns_topic" "alarms" {
  name = "token-broker-alarms-${var.stage_name}"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Note: CloudWatch log group is created by Lambda module, not here
# Removed aws_cloudwatch_log_group resource to avoid conflicts

data "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${var.lambda_function_name}"
}

resource "aws_cloudwatch_log_metric_filter" "auth_failed" {
  name           = "AuthFailed-${var.stage_name}"
  log_group_name = data.aws_cloudwatch_log_group.lambda.name

  # Match either NotAuthorizedException or UserNotFoundException in logs
  pattern = "{ ($.errorName = \"NotAuthorizedException\") || ($.errorName = \"UserNotFoundException\") }"

  metric_transformation {
    name      = "AuthFailed"
    namespace = "TokenBroker"
    value     = "1"
  }
}
resource "aws_cloudwatch_metric_alarm" "auth_failed_spike" {
  alarm_name          = "AuthFailedSpike-${var.stage_name}"
  alarm_description   = "High number of authentication failures (possible credential stuffing/brute force)."
  namespace           = "TokenBroker"
  metric_name         = aws_cloudwatch_log_metric_filter.auth_failed.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.auth_failed_threshold_5m
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "LambdaErrors-${var.stage_name}"
  alarm_description   = "Lambda errors detected."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.lambda_errors_threshold_5m
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "LambdaThrottles-${var.stage_name}"
  alarm_description   = "Lambda throttles detected (reserved concurrency may be too low or traffic spike)."
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.lambda_throttles_threshold_5m
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}
