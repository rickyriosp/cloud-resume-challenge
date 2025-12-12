output "aws_s3_frontend_bucket_name" {
  description = "Name of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution for the frontend"
  value       = aws_cloudfront_distribution.s3_frontend.id
}