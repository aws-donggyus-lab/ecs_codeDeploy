terraform {
  backend "s3" {
    bucket = "dk-poc-tfstate"
    key    = "jenkins/terraform.json"
    region = "ap-northeast-2"
  }
}