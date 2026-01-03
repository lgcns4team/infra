########################################
# IAM Role for EC2 (SSM + Prometheus EC2 SD)
########################################
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${local.name_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# SSM 기본 권한
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Prometheus EC2 Service Discovery용 DescribeInstances 권한(역할에 추가)
resource "aws_iam_role_policy" "prometheus_ec2_sd" {
  name = "${local.name_prefix}-prometheus-ec2-sd"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["ec2:DescribeInstances", "ec2:DescribeTags", "ec2:DescribeRegions"],
      Resource = "*"
    }]
  })
}

# Instance Profile (EC2/ASG에 연결되는 '껍데기')
# resource "aws_iam_instance_profile" "ec2_codedeploy_profile" {
# name = "${local.name_prefix}-ec2-codedeploy-profile"
# role = aws_iam_role.ec2_ssm_role.name
# }