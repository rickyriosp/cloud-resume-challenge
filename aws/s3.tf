# See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
data "aws_iam_policy_document" "frontend_origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject", "s3:PutObject"]

    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    # condition {
    #   test     = "StringEquals"
    #   variable = "AWS:SourceArn"
    #   values   = [aws_cloudfront_distribution.frontend.arn]
    # }
  }
}

resource "aws_s3_bucket" "frontend" {
  bucket = "cloud-resume-challenge-frontend-as61z23"

  # Allow Terraform to delete non-empty buckets (will remove all objects)
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3control_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.arn
  policy = data.aws_iam_policy_document.frontend_origin_bucket_policy.json
}