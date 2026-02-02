#Create WAFv2 IP Sets for allowlist and blocklist
resource "aws_wafv2_ip_set" "allow" {
  count              = length(var.allow_ip_cidrs) > 0 ? 1 : 0
  name               = "${var.name}-allow"
  description        = "Allowlist IP ranges"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.allow_ip_cidrs
  tags               = var.tags
}
#Create WAFv2 IP Sets for allowlist and blocklist
resource "aws_wafv2_ip_set" "block" {
  count              = length(var.block_ip_cidrs) > 0 ? 1 : 0
  name               = "${var.name}-block"
  description        = "Blocklist IP ranges"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.block_ip_cidrs
  tags               = var.tags
}
#Create WAFv2 Web ACL
resource "aws_wafv2_web_acl" "this" {
  name        = "${var.name}-web-acl"
  description = "WAF for ${var.name}"
  scope       = var.scope
  tags        = var.tags

  # What happens if no rules match:
  default_action {
    allow {}
  }

  # Rule 1 (highest priority): allow trusted IPs (optional)
  dynamic "rule" {
    for_each = length(var.allow_ip_cidrs) > 0 ? [1] : []
    content {
      name     = "allow-trusted-ips"
      priority = 0

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allow[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-allow-trusted-ips"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rule 2: block known bad IPs (optional)
  dynamic "rule" {
    for_each = length(var.block_ip_cidrs) > 0 ? [1] : []
    content {
      name     = "block-bad-ips"
      priority = 1

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.block[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-block-bad-ips"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rule 3: global rate limit (broad protection)
  rule {
    name     = "global-rate-limit-per-ip"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.global_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-global-rate-limit-per-ip"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: path-specific rate limit for /token (stricter)
  rule {
    name     = "token-path-rate-limit"
    priority = 11

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.token_path_rate_limit
        aggregate_key_type = "IP"
        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "EXACTLY"
            search_string         = "/token"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-token-path-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Web ACL level visibility (overall metrics/log sampling)
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-web-acl"
    sampled_requests_enabled   = true
  }
}
# Associate Web ACL to API Gateway stage/resource {attach WAF to API Gateway}
resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = var.target_resource_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
# WAF Logging Configuration (optional)
resource "aws_wafv2_web_acl_logging_configuration" "this" {
    count = var.enable_logging ? 1 : 0
    resource_arn = aws_wafv2_web_acl.this.arn
    log_destination_configs = var.log_destination_arns 
    redacted_fields {
        single_header {
        name = "Authorization"
        }
    }
}