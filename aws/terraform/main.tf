locals {
  region         = "us-east-1"
  domain         = "riosr.com"
  subdomain      = "resume"
  api_subdomain  = "api-counter"
  s3_origin_id   = "cloudResumeS3Origin"
  python_version = "python3.14"
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