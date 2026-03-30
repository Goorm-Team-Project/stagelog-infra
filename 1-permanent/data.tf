data "terraform_remote_state" "ephemeral" {
  backend = "s3"

  config = {
    bucket = "stagelog-tfstate"
    key    = "develop/ephemeral/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "tls_certificate" "github_actions_oidc" {
  url = "https://token.actions.githubusercontent.com"
}
