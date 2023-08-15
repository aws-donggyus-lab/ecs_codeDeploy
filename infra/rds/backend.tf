terraform {
  backend "s3" {
    bucket = "dk-poc-tfstate"
    key    = "rds/terraform.json"
    region = "ap-northeast-2"
  }
}