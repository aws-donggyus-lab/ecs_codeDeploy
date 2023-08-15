terraform {
  backend "s3" {
    bucket = "dk-poc-tfstate"
    key    = "vpc/terraform.json"
    region = "ap-northeast-2"
  }
}