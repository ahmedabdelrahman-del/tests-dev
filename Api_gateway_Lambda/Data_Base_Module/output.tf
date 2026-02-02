output "table_name"       { value = aws_dynamodb_table.ratelimit.name }
output "table_arn"        { value = aws_dynamodb_table.ratelimit.arn }
output "table_stream_arn" { value = try(aws_dynamodb_table.ratelimit.stream_arn, null) }
