data "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  name = var.origin_request_policy_name
}

data "aws_cloudfront_cache_policy" "cache_policy" {
  name = var.cache_policy_name
}

resource "aws_acm_certificate" "iclosed-fe-ssl-cert" {
  domain_name       = var.fe_domain_name
  validation_method = "DNS"

  tags = {
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}


#SSL records from AWS ACM

resource "aws_route53_record" "iclosed-fe-ssl-records" {
  for_each = {
    for dvo in aws_acm_certificate.iclosed-fe-ssl-cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.iclosed.zone_id
  depends_on = [
    aws_acm_certificate.iclosed-fe-ssl-cert
  ]
}

resource "aws_acm_certificate_validation" "iclosed-fe-ssl-validator" {
  certificate_arn         = aws_acm_certificate.iclosed-fe-ssl-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.iclosed-fe-ssl-records : record.fqdn]
}

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.3"

  aliases             = [var.fe_domain_name]
  comment             = var.fe_domain_name
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false
  default_root_object = "index.html"
  custom_error_response = [{
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }]
  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "cloudfront-s3-access"
  }

  origin = {
    s3_one = {
      domain_name = "${aws_s3_bucket.fe-s3.bucket_regional_domain_name}"
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
      }
      origin_shield = {
        enabled              = true
        origin_shield_region = "eu-west-2"
      }
    }
  }


  default_cache_behavior = {
    target_origin_id           = "s3_one"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods             = ["GET", "HEAD"]
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id
    cache_policy_id            = data.aws_cloudfront_cache_policy.cache_policy.id
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
    compress                   = true
    query_string               = false
    use_forwarded_values       = false

  }

  viewer_certificate = {
    acm_certificate_arn = "${aws_acm_certificate_validation.iclosed-fe-ssl-validator.certificate_arn}"
    ssl_support_method  = "sni-only"
  }
  depends_on = [
    aws_s3_bucket.fe-s3,
    aws_acm_certificate_validation.iclosed-fe-ssl-validator
  ]
}

data "aws_iam_policy_document" "s3_cf_iam_doc" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.fe-s3.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [module.cdn.cloudfront_origin_access_identity_iam_arns[0]]
    }
  }
  depends_on = [
    module.cdn
  ]
}


resource "aws_s3_bucket_policy" "s3_policy_cf_only" {
  bucket = aws_s3_bucket.fe-s3.id
  policy = data.aws_iam_policy_document.s3_cf_iam_doc.json
  depends_on = [
    aws_s3_bucket.fe-s3
  ]
}

resource "aws_route53_record" "cf-record" {

  allow_overwrite = true
  name            = var.fe_domain_name
  type            = "A"
  zone_id         = data.aws_route53_zone.iclosed.zone_id
  alias {
    evaluate_target_health = false
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
  }
}
