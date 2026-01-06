variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.250.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.250.0.0/24"
}