resource "aws_db_subnet_group" "db" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-db-subnet-group" })
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

  multi_az            = true
  publicly_accessible = false

  skip_final_snapshot = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-mariadb" })
}