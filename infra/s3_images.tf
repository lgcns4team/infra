resource "aws_s3_bucket" "images" {
  bucket = var.image_bucket_name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-images"
    Type = "image-storage"
  })
}