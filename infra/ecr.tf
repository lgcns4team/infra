resource "aws_ecr_repository" "backend" {
  name                 = var.ecr_repo_backend_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

output "ecr_backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}