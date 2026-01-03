########################
# Secrets Manager - App Env (DB 포함)
########################

locals {
  # RDS 엔드포인트는 "host:port" 또는 별도 endpoint/port로 제공됩니다.
  # aws_db_instance.mariadb.address 는 host만 나오는 경우가 많아 address + port 조합을 권장합니다.
  db_host = aws_db_instance.mariadb.address
  db_port = aws_db_instance.mariadb.port

  # MariaDB JDBC 예시
  jdbc_url = "jdbc:mariadb://${local.db_host}:${local.db_port}/${var.db_name}?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Seoul"

  base_secret_map = {
    ENV         = var.app_env
    DB_HOST     = local.db_host
    DB_PORT     = tostring(local.db_port)
    DB_NAME     = var.db_name
    DB_USERNAME = var.db_username
    DB_PASSWORD = var.db_password
    DB_URL      = local.jdbc_url

    # 필요하면 아래처럼 기본값도 같이 넣을 수 있습니다.
    # SPRING_PROFILES_ACTIVE = "dev"
  }

  secret_payload = merge(local.base_secret_map, var.extra_app_env)
}

# resource "aws_secretsmanager_secret" "app_env" {
#   name                    = "${local.name_prefix}-app-env"
#   description             = "Application environment variables for ${local.name_prefix} (includes DB settings)"
#   recovery_window_in_days = 7

#   tags = local.common_tags
# }

# resource "aws_secretsmanager_secret_version" "app_env" {
#   secret_id     = aws_secretsmanager_secret.app_env.id
#   secret_string = jsonencode(local.secret_payload)
# }



########################################
# Secrets Manager - App Env (DB 등)
########################################

# 이름 충돌 방지용 (필요 시 v2로 변경)
variable "app_env_secret_name" {
  type    = string
  default = "nok-nok-dev-app-env"
}

resource "aws_secretsmanager_secret" "app_env" {
  name                    = var.app_env_secret_name
  recovery_window_in_days = 7

  tags = local.common_tags
}

# Secret 내용(JSON)
# - RDS endpoint 기반으로 JDBC URL 생성
# - 추가 환경변수도 여기에 계속 넣으면 됨
resource "aws_secretsmanager_secret_version" "app_env" {
  secret_id = aws_secretsmanager_secret.app_env.id

  secret_string = jsonencode({
    DB_HOST     = aws_db_instance.mariadb.address
    DB_PORT     = tostring(aws_db_instance.mariadb.port)
    DB_NAME     = "noknok"
    DB_USERNAME = var.db_username
    DB_PASSWORD = var.db_password

    # 스프링에서 바로 쓰기 편한 형태도 함께 제공
    SPRING_DATASOURCE_URL      = "jdbc:mariadb://${aws_db_instance.mariadb.address}:${aws_db_instance.mariadb.port}/noknok"
    SPRING_DATASOURCE_USERNAME = var.db_username
    SPRING_DATASOURCE_PASSWORD = var.db_password

    # 필요 시 추가
    # JWT_SECRET = "..."
    # REDIS_HOST = "..."
  })
}

########################################
# IAM - EC2 Role이 Secret 읽을 수 있게
########################################

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

