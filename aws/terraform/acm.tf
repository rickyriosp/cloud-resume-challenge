resource "aws_acm_certificate" "resume_domain" {
  domain_name       = "${local.subdomain}.${local.domain}"
  validation_method = "DNS"

  validation_option {
    domain_name       = "${local.subdomain}.${local.domain}"
    validation_domain = local.domain
  }
}

resource "aws_acm_certificate" "api_domain" {
  domain_name       = "${local.api_subdomain}.${local.domain}"
  validation_method = "DNS"

  validation_option {
    domain_name       = "${local.api_subdomain}.${local.domain}"
    validation_domain = local.domain
  }
}