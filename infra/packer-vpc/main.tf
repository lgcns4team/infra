########################
# VPC (Packer build only)
########################
resource "aws_vpc" "packer" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "packer-build-vpc"
    Purpose = "packer-ami-build"
  }
}

########################
# Internet Gateway
########################
resource "aws_internet_gateway" "packer" {
  vpc_id = aws_vpc.packer.id

  tags = {
    Name = "packer-build-igw"
  }
}

########################
# Public Subnet (1 AZ)
########################
resource "aws_subnet" "packer_public" {
  vpc_id                  = aws_vpc.packer.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "packer-build-public-subnet"
  }
}

########################
# Route Table
########################
resource "aws_route_table" "packer_public" {
  vpc_id = aws_vpc.packer.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.packer.id
  }

  tags = {
    Name = "packer-build-public-rt"
  }
}

########################
# Route Table Association
########################
resource "aws_route_table_association" "packer_public" {
  subnet_id      = aws_subnet.packer_public.id
  route_table_id = aws_route_table.packer_public.id
}