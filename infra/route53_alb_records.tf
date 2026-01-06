########################
# Route53 - CloudFront (root + www)
########################
resource "aws_route53_record" "root_alias_cf" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.root_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_alias_cf" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

########################
# Route53 - ALB (api / jenkins / grafana)
########################
resource "aws_route53_record" "api_alias_alb" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.api_subdomain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "jenkins_alias_alb" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.jenkins_subdomain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "grafana_alias_alb" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.grafana_subdomain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}