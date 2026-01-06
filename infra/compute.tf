########################
# Launch Template for Spring Boot ASG (t2.micro)
########################
resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-app-"
  image_id      = var.app_ami_id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # ✅ ASG EC2 → SSM + CodeDeploy + ECR Pull (반드시 필요)
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_codedeploy_profile.name
  }

  # ✅ AMI가 바뀌어도 SSM 접속 보장 (SSM Agent enable/restart)
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Amazon Linux 계열 기준 (yum/dnf)
    if command -v yum >/dev/null 2>&1; then
      yum install -y amazon-ssm-agent || true
    elif command -v dnf >/dev/null 2>&1; then
      dnf install -y amazon-ssm-agent || true
    fi

    systemctl enable amazon-ssm-agent || true
    systemctl restart amazon-ssm-agent || true
  EOF
  )

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      volume_size           = 30
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app"
      Role = "springboot-app"
    })
  }
}

########################
# Auto Scaling Group (Spring Boot)
########################
resource "aws_autoscaling_group" "app" {
  name_prefix         = "${local.name_prefix}-asg-app-"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 2
  vpc_zone_identifier = aws_subnet.private_app[*].id

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.api.arn]

  tag {
    key                 = "Role"
    value               = "springboot-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

########################
# Fixed EC2 (Jenkins / Monitoring)
########################
resource "aws_instance" "monitoring" {
  ami                    = var.app_ami_id
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.private_app[0].id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  # ✅ Monitoring 서버도 SSM 접속 필요하므로 SSM 포함된 프로파일 사용 권장
  iam_instance_profile = aws_iam_instance_profile.ec2_codedeploy_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-monitoring"
    Role = "monitoring"
  })
}

resource "aws_instance" "jenkins" {
  ami                    = var.app_ami_id
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.private_app[1].id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # ✅ Jenkins 전용 (ECR push + S3 put + CodeDeploy trigger)
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-jenkins"
    Role = "jenkins"
  })
}
