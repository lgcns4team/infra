# App(ASG) SG - 일단 VPC 내부 8080만 허용 (ALB는 다음 단계에서 추가 시 ALB SG로 제한 권장)
resource "aws_security_group" "app_sg" {
  name   = "${local.name_prefix}-app-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description     = "App port from ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "App port from Monitoring only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-app-sg" })
}

# Monitoring SG (Prometheus 9090, Grafana 3000)
resource "aws_security_group" "monitoring_sg" {
  name   = "${local.name_prefix}-monitoring-sg"
  vpc_id = aws_vpc.this.id

  # Grafana UI (내부에서만)
  ingress {
    description = "Grafana from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  # Prometheus UI (내부에서만)
  ingress {
    description = "Prometheus from VPC"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-monitoring-sg" })
}

# Jenkins SG (8080 UI, 50000 agent)
resource "aws_security_group" "jenkins_sg" {
  name   = "${local.name_prefix}-jenkins-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description = "Jenkins UI from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  ingress {
    description = "Jenkins agent port from VPC"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-jenkins-sg" })
}

# DB SG - App SG에서만 3306 허용
resource "aws_security_group" "db_sg" {
  name   = "${local.name_prefix}-db-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description     = "MariaDB from app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-db-sg" })
}