data "aws_route53_zone" "this" {
  name         = "${var.root_domain}."
  private_zone = false
}