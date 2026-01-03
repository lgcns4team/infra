########################
# Global / Project
########################
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "nok-nok"
}

variable "env" {
  description = "Environment name (dev, stg, prod)"
  type        = string
  default     = "dev"
}

########################
# AMI
########################
variable "app_ami_id" {
  description = "Golden AMI ID built by Packer (Ubuntu 24.04)"
  type        = string
}

########################
# VPC / Subnet CIDR
########################
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (2 AZ)"
  type        = list(string)
  default = [
    "10.10.0.0/24",
    "10.10.1.0/24"
  ]
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDR blocks"
  type        = list(string)
  default = [
    "10.10.10.0/24",
    "10.10.11.0/24"
  ]
}

variable "private_db_subnet_cidrs" {
  description = "Private DB subnet CIDR blocks"
  type        = list(string)
  default = [
    "10.10.20.0/24",
    "10.10.21.0/24"
  ]
}

########################
# RDS
########################
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "noknok"
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

########################
# ASG
########################
variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}




variable "root_domain" {
  type    = string
  default = "bfree-kiosk.com"
}

variable "frontend_bucket_name" {
  description = "전역 유니크한 S3 버킷명"
  type        = string
}

variable "api_subdomain" {
  type    = string
  default = "api"
}

variable "jenkins_subdomain" {
  type    = string
  default = "jenkins"
}

variable "grafana_subdomain" {
  type    = string
  default = "grafana"
}


variable "ecr_repo_backend_name" {
  type        = string
  description = "ECR repository name for backend image"
  default     = "bfree-kiosk-backend"
}


variable "codedeploy_bucket_name" {
  type        = string
  description = "S3 bucket for CodeDeploy revision bundles (zip)"
}

variable "codedeploy_app_name" {
  type        = string
  default     = "nok-nok-dev-codedeploy-app"
  description = "CodeDeploy application name"
}

variable "codedeploy_deployment_group_name" {
  type        = string
  default     = "nok-nok-dev-dg"
  description = "CodeDeploy deployment group name"
}


variable "image_bucket_name" {
  description = "S3 bucket for uploaded images"
  type        = string
}


# 이미 var.db_username, var.db_password 를 쓰고 있으니 중복이면 추가하지 마세요.
# variable "db_username" {}
# variable "db_password" { sensitive = true }

variable "app_env" {
  type    = string
  default = "dev"
}

# 예: Spring profile, 기타 환경변수도 같이 넣고 싶으면 변수로 받는 방식이 가장 깔끔합니다.
variable "extra_app_env" {
  description = "추가로 Secrets Manager에 넣을 앱 환경변수들 (key/value)"
  type        = map(string)
  default     = {}
}
