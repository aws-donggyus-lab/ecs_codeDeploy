terraform {
  backend "s3" {
    bucket = "dk-poc-tfstate"
    key    = "ecs/terraform.json"
    region = "ap-northeast-2"
  }
}