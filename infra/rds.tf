resource "aws_db_subnet_group" "db" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-db-subnet-group" })
}

########################
# Parameter Group: utf8mb4 + Asia/Seoul
########################
resource "aws_db_parameter_group" "mariadb_kor" {
  name   = "${local.name_prefix}-mariadb-kor"
  family = "mariadb10.11"

  # 한글/이모지까지 고려 utf8mb4
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  # 접속/세션 기본도 utf8mb4로
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  # 한국 시간대 (RDS MariaDB에서 지원되는 값이어야 함)
  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-mariadb-kor" })
}

resource "aws_db_instance" "mariadb" {
  identifier     = "${local.name_prefix}-mariadb"
  engine         = "mariadb"
  engine_version = "10.11.15"

  instance_class    = "db.t3.medium"
  allocated_storage = 30
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  #  파라미터 그룹 연결
  parameter_group_name = aws_db_parameter_group.mariadb_kor.name

  multi_az            = true
  publicly_accessible = false

  skip_final_snapshot = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-mariadb" })
}
