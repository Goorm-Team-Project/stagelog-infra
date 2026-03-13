terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "stagelog-tfstate"
    key            = "develop/ephemeral/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Project = "stagelog"
    }
  }
}

variable "env" {
  type    = string
  default = "dev"
}

locals {
  prefix = var.env
  vpc_id = data.terraform_remote_state.permanent.outputs.vpc_id

  subnet_public_01 = data.terraform_remote_state.permanent.outputs.public_subnet_ids["public-01"]
  subnet_public_02 = data.terraform_remote_state.permanent.outputs.public_subnet_ids["public-02"]

  subnet_private_01 = data.terraform_remote_state.permanent.outputs.private_subnet_ids["private-01"]
  subnet_private_02 = data.terraform_remote_state.permanent.outputs.private_subnet_ids["private-02"]

  rtb_private_01 = data.terraform_remote_state.permanent.outputs.private_route_table_ids["private-rtb-01"]
  rtb_private_02 = data.terraform_remote_state.permanent.outputs.private_route_table_ids["private-rtb-02"]

  alb_sg     = data.terraform_remote_state.permanent.outputs.security_groups["alb_sg"]
  bastion_sg = data.terraform_remote_state.permanent.outputs.security_groups["bastion_sg"]

  cloudfront_distribution_domain_name    = try(data.terraform_remote_state.permanent.outputs.cloudfront_distribution_domain_name, null) != null ? data.terraform_remote_state.permanent.outputs.cloudfront_distribution_domain_name : ""
  cloudfront_distribution_hosted_zone_id = try(data.terraform_remote_state.permanent.outputs.cloudfront_distribution_hosted_zone_id, null) != null ? data.terraform_remote_state.permanent.outputs.cloudfront_distribution_hosted_zone_id : ""

  eks_role            = data.aws_iam_role.eks_role.arn
  eks_node_group_role = data.aws_iam_role.eks_node_group_role.arn
}
