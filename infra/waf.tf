########################
# WAF - CloudFront (Global)
########################
resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.use1
  name     = "${local.name_prefix}-cf-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  ########################
  # 1. HTTP Flood 방어 (IP 기준 Rate Limit)
  ########################
  rule {
    name     = "RateLimitHttpFlood"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitHttpFlood"
      sampled_requests_enabled   = true
    }
  }

  ########################
  # 2. OWASP Top 10 + XSS + 기본 공격 방어
  ########################
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

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
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

########################
# WAF - ALB (Regional)
########################
resource "aws_wafv2_web_acl" "alb" {
  name  = "${local.name_prefix}-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Jenkins login endpoint 예외 처리 (SQLi 오탐 회피)
  rule {
    name     = "AllowJenkinsLoginPaths"
    priority = 0

    action {
      allow {}
    }

    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "EXACTLY"
            search_string         = "/login"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "EXACTLY"
            search_string         = "/j_spring_security_check"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        # !초기 설정/플러그인 설치 시 필요할 수 있음
        statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "/setupWizard"
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
      metric_name                = "AllowJenkinsLoginPaths"
      sampled_requests_enabled   = true
    }
  }

  # 기존 룰은 priority를 1, 2로 밀어줌
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "alb-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}


########################
# WAF Associations
########################
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}
