data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "nok-nok-dev"

  azs = ["ap-northeast-2a", "ap-northeast-2c"]

  common_tags = {
    Project = "nok-nok"
    Env     = "dev"
    Owner   = "terraform"
  }
}