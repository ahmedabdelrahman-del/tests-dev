resource "aws_dynamodb_table" "ratelimit" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "k"

  attribute {
    name = "k"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection

  tags = var.tags
}
