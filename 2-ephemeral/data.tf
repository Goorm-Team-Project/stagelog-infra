data "terraform_remote_state" "permanent" {
  backend = "s3"

  config = {
    bucket = "stagelog-tfstate"
    key    = "develop/permanent/terraform.tfstate" 
    region = "ap-northeast-2"
  }
}