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
    key = "develop/permanent/terraform.tfstate"
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