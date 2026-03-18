data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "stagelog-tfstate"
    key    = "develop/eks/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
