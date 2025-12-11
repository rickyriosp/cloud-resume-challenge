resource "aws_s3_bucket" "frontend-bucket" {
  bucket = "cloud-resume-challenge-frontend-as61z23"

  force_destroy = true
}