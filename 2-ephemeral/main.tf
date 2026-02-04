terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "stagelog-tfstate"
    key = "develop/ephemeral/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
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

locals {
  vpc_id = data.terraform_remote_state.permanent.outputs.vpc_id

  subnet_public_01 = data.terraform_remote_state.permanent.outputs.public_subnet_ids["public-01"]
  subnet_public_02 = data.terraform_remote_state.permanent.outputs.public_subnet_ids["public-02"]
  subnet_public_03 = data.terraform_remote_state.permanent.outputs.public_subnet_ids["public-03"]

  subnet_private_01 = data.terraform_remote_state.permanent.outputs.private_subnet_ids["private-01"]
  subnet_private_02 = data.terraform_remote_state.permanent.outputs.private_subnet_ids["private-02"]

  rtb_private_01 = data.terraform_remote_state.permanent.outputs.private_route_table_ids["private-rtb-01"]
  rtb_private_02 = data.terraform_remote_state.permanent.outputs.private_route_table_ids["private-rtb-02"]

  alb_sg = data.terraform_remote_state.permanent.outputs.security_groups["alb_sg"]
  frontend_sg = data.terraform_remote_state.permanent.outputs.security_groups["frontend_sg"]
  backend_sg = data.terraform_remote_state.permanent.outputs.security_groups["backend_sg"]
  bastion_sg = data.terraform_remote_state.permanent.outputs.security_groups["bastion_sg"]

  iam_SSM_CloudWatchlog_Role = data.terraform_remote_state.permanent.outputs.iam_roles["SSM_CloudWatchlog_Role"]
  iam_Combine_SSM_CloudWatchlog_S3_Uploader = data.terraform_remote_state.permanent.outputs.iam_roles["Combine_SSM_CloudWatchlog_S3_Uploader"]

  backend_iam_role_profile = data.terraform_remote_state.permanent.outputs.iam_instance_backend_profile_name
  frontend_iam_role_profile = data.terraform_remote_state.permanent.outputs.iam_frontend_profile_name
}

# local.subnet-public-01 과 같은 이름으로 사용