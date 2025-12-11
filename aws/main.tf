locals {
  region       = "us-east-1"
  domain       = "riosr.com"
  subdomain    = "resume"
  s3_origin_id = "cloudResumeS3Origin"
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