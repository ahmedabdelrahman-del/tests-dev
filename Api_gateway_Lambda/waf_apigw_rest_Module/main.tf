resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-webacl"
    sampled_requests_enabled   = true
  }

  # ---------- 1) Rate-based rule (IP flood protection) ----------
  rule {
    name     = "ip-rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.ip_rate_limit_5m
        aggregate_key_type = "IP"

        # Scope down to /token* only (recommended)
        dynamic "scope_down_statement" {
          for_each = var.protect_token_paths_only ? [1] : []
          content {
            byte_match_statement {
              search_string = "/token"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "STARTS_WITH"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-ipRateLimit"
      sampled_requests_enabled   = true
    }
  }

  # ---------- 2) AWS Managed Rules (optional) ----------
  dynamic "rule" {
    for_each = var.enable_managed_rules ? [1] : []
    content {
      name     = "aws-managed-common"
      priority = 2

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-commonRules"
        sampled_requests_enabled   = true
      }
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = var.apigw_stage_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
