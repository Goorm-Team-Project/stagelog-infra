data "terraform_remote_state" "permanent" {
  backend = "s3"

  config = {
    bucket = "stagelog-tfstate"
    key    = "develop/permanent/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "stagelog-tfstate"
    key    = "develop/eks/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_acm_certificate" "api_domain" {
  domain      = var.api_domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}
