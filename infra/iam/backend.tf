terraform {
  backend "s3" {
    bucket = "dk-poc-tfstate"
    key    = "iam/terraform.json"
    region = "ap-northeast-2"
  }
}