data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "dk-poc-tfstate"
    key    = "vpc/terraform.json"
    region = "ap-northeast-2"
  }
}

