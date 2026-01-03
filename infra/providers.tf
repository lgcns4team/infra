provider "aws" {
  region = "ap-northeast-2"
}

# CloudFront 인증서(ACM)는 반드시 us-east-1
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}