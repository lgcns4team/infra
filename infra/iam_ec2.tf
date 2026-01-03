########################
# IAM - EC2가 Secrets Manager 읽기 (Terraform-managed secret)
########################
resource "aws_iam_role_policy" "ec2_secrets_read" {
  name = "${local.name_prefix}-ec2-secrets-read"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadAppEnvSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.app_env.arn
      }
    ]
  })
}
