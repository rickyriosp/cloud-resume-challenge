locals {
  region = "us-east-1"
  domain = "resume.riosr.com"
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Application = "cloud-resume-challenge"
      Environment = "Dev"
    }
  }
}