packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "ami_name" {
  type    = string
  default = "app-golden-ami-ubuntu-24-04"
}

# Terraform(packer-vpc) apply 결과로 나온 값으로 교체하세요
variable "packer_vpc_id" {
  type = string
}

# Terraform(packer-vpc) apply 결과로 나온 값으로 교체하세요
variable "packer_subnet_id" {
  type = string
}

source "amazon-ebs" "app" {
  region        = var.region
  instance_type = "t2.micro"

  # Default VPC 없는 계정 대응: 빌드 전용 VPC/Subnet 명시
  vpc_id    = var.packer_vpc_id
  subnet_id = var.packer_subnet_id

  associate_public_ip_address = true

  # Ubuntu 24.04 LTS (Noble) - gp3 경로
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  ssh_username = "ubuntu"

  ami_name = "${var.ami_name}-{{timestamp}}"

  tags = {
    Name        = "packer-app-ami"
    OS          = "ubuntu-24.04"
    BuiltBy     = "packer"
    Environment = "base"
  }
}

build {
  name    = "app-ami-build"
  sources = ["source.amazon-ebs.app"]

  provisioner "shell" {
    script = "scripts/install_base.sh"
  }
}