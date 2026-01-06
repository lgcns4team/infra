# Secrets Manager
variable "app_env_secret_name" {
  type    = string
  default = "nok-nok-dev-app-env"
}

locals {
  db_host = aws_db_instance.mariadb.address
  db_port = aws_db_instance.mariadb.port
  
  jdbc_url = "jdbc:mariadb://${local.db_host}:${local.db_port}/${var.db_name}?useUnicode=true&characterEncoding=utf8&serverTimezone=UTC"
}

# Secret 본체 (주의: 이미 AWS에 존재하는 Secret이면 반드시 terraform import로 먼저 state에 넣고 apply 하세요)
resource "aws_secretsmanager_secret" "app_env" {
  name = var.app_env_secret_name

  # 이미 존재하는 Secret을 '새로 만들지' 않도록 import가 선행되어야 합니다.
  # recovery_window_in_days 등을 여기서 바꾸면 정책 변경으로 동작할 수 있으니 필요할 때만 추가하세요.

  tags = {
    Env     = var.app_env
    Project = "nok-nok"
    Owner   = "terraform"
  }
}

# Secret 값(버전) - RDS endpoint/port 기반으로 동적으로 생성
resource "aws_secretsmanager_secret_version" "app_env" {
  secret_id = aws_secretsmanager_secret.app_env.id

  secret_string = jsonencode({
    DRIVER_NAME      = "org.mariadb.jdbc.Driver"
    DRIVER_URL       = local.jdbc_url
    DRIVER_USER_NAME = var.db_username
    DRIVER_PASSWORD  = var.db_password
  })
}

# IAM - EC2 Role이 Secret 읽을 수 있게

data "aws_iam_policy_document" "ec2_secrets_read" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.app_env.arn
    ]
  }
}

