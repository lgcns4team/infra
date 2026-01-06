########################
# CodeDeploy Service Role (CodeDeploy가 사용하는 역할)
########################
resource "aws_iam_role" "codedeploy_service_role" {
  name = "${local.name_prefix}-codedeploy-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "codedeploy.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_attach" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

########################
# EC2 Role(SSM Role)에 CodeDeploy/S3/ECR 권한 추가
# - EC2가 SSM 접속 + S3 배포번들 읽기 + (선택)ECR pull 수행
########################

# 배포 번들 S3에서 읽기 (CodeDeploy agent가 필요)
resource "aws_iam_role_policy" "ec2_codedeploy_s3_read" {
  name = "${local.name_prefix}-ec2-codedeploy-s3-read"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      Resource = [
        aws_s3_bucket.codedeploy.arn,
        "${aws_s3_bucket.codedeploy.arn}/*"
      ]
    }]
  })
}

# (선택) EC2에서 ECR pull 권한
# - 현재 당신은 "개인 DockerHub pull"을 쓴다고 했지만,
#   이후 ECR로 바꿀 가능성이 높으니 유지해도 무방합니다.
resource "aws_iam_role_policy" "ec2_ecr_pull" {
  name = "${local.name_prefix}-ec2-ecr-pull"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = aws_ecr_repository.backend.arn
      }
    ]
  })
}

########################
# EC2 Instance Profile (ASG/고정EC2에 부착)
# - compute.tf에서 aws_iam_instance_profile.ec2_codedeploy_profile를 참조하므로
#   이 이름으로 생성합니다.
########################
resource "aws_iam_instance_profile" "ec2_codedeploy_profile" {
  name = "${local.name_prefix}-ec2-codedeploy-profile"
  role = aws_iam_role.ec2_ssm_role.name
}