########################
# IAM - Jenkins Role (CI/CD 실행자)
########################

resource "aws_iam_role" "jenkins_role" {
  name = "${local.name_prefix}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

########################
# Instance Profile for Jenkins EC2
########################
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${local.name_prefix}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

########################
# SSM (Jenkins 서버 접속/운영)
########################
resource "aws_iam_role_policy_attachment" "jenkins_ssm_core" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

########################
# Managed Policy - Jenkins CI/CD permissions
#  - ECR Push/Pull (repo 제한)
#  - S3 Upload/Download (CodeDeploy bucket 제한)
#  - CodeDeploy Trigger
########################
resource "aws_iam_policy" "jenkins_ci_cd" {
  name        = "${local.name_prefix}-jenkins-ci-cd"
  description = "Jenkins CI/CD: ECR push, S3 upload, CodeDeploy trigger"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      ########################################
      # ECR Auth (토큰은 리전 내 모든 ECR에 대해 필요 -> Resource "*")
      ########################################
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },

      ########################################
      # ECR Push/Pull (특정 Repository로 제한)
      ########################################
      {
        Sid    = "ECRPushPullRepoScoped"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = [
          aws_ecr_repository.backend.arn
        ]
      },

      ########################################
      # S3 Upload/Download (CodeDeploy bucket로 제한)
      ########################################
      {
        Sid    = "S3CodeDeployBucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.codedeploy.arn
        ]
      },
      {
        Sid    = "S3CodeDeployObjectRW"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.codedeploy.arn}/*"
        ]
      },

      ########################################
      # CodeDeploy Trigger (배포 트리거)
      # 리소스 제한을 더 강하게 하고 싶으면 app/deployment-group ARN으로 제한 가능
      ########################################
      {
        Sid    = "CodeDeployTrigger"
        Effect = "Allow"
        Action = [
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:GetApplication",
          "codedeploy:ListDeployments"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ci_cd_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_ci_cd.arn
}
