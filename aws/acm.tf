resource "aws_acm_certificate" "resume_domain" {
  domain_name       = "${local.subdomain}.${local.domain}"
  validation_method = "DNS"

  validation_option {
    domain_name       = "${local.subdomain}.${local.domain}"
    validation_domain = local.domain
  }
}