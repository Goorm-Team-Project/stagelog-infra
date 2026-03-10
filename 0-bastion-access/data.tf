data "terraform_remote_state" "permanent" {
  backend = "s3"

  config = {
    bucket = "stagelog-tfstate"
    key    = "develop/permanent/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
