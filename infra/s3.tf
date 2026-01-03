resource "aws_s3_bucket" "app" {
  bucket = "${local.name_prefix}-bucket"
  tags   = local.common_tags
}