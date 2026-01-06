resource "aws_s3_bucket" "codedeploy" {
  bucket = var.codedeploy_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "codedeploy" {
  bucket                  = aws_s3_bucket.codedeploy.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}