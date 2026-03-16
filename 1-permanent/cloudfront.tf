# cloudfront.tf

# AWS Managed Cache Policy (필수: cache_policy_id 제공)
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# CloudFront Cache Policy (비활성화)
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

# CloudFront Origin Request Policy (모든 뷰어 헤더 제외)
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

# CloudFront Origin Access Control Uploads
resource "aws_cloudfront_origin_access_control" "uploads_oac" {
  name                              = "stagelog-uploads-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Origin Access Control Stagelog
resource "aws_cloudfront_origin_access_control" "stagelog_oac" {
  name                              = "stagelog-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution Upload
resource "aws_cloudfront_distribution" "uploads_cdn" {
  enabled = true

  tags = { Name = "stagelog-cloudfront-uploads" }

  origin {
    domain_name              = aws_s3_bucket.stagelog_dev_uploads_v2.bucket_regional_domain_name
    origin_id                = "uploads-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.uploads_oac.id
  }

  default_cache_behavior {
    target_origin_id       = "uploads-s3"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.uploads_cf_acl.arn
}

# CloudFront Distribution stagelog
resource "aws_cloudfront_distribution" "stagelog_cdn" {
  enabled = true
  aliases = ["pearlinvest.click", "www.pearlinvest.click"]

  tags = { Name = "stagelog-cloudfront" }

  # S3 오리진 (프론트엔드)
  origin {
    domain_name              = aws_s3_bucket.stagelog_frontend.bucket_regional_domain_name
    origin_id                = "stagelog-frontend-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.stagelog_oac.id
  }

  # API Gateway 오리진 (core routes, REST API v1)
  origin {
    domain_name = var.core_api_execute_domain_name
    origin_id   = "stagelog-core-rest-api"
    origin_path = "/${var.core_api_stage_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # /api/* -> REST API (core routes)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "stagelog-core-rest-api"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id                       # API Gateway 캐시 정책
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id # API Gateway 오리진 요청 정책
  }

  # /* -> S3
  default_cache_behavior {
    target_origin_id = "stagelog-frontend-s3"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id # S3 캐시 정책
  }

  # SPA를 위한 에러 응답 설정: 403/404 발생 시 index.html로 리다이렉트
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # 제한 사항
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL 설정
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # WAF 설정
  web_acl_id = aws_wafv2_web_acl.api_waf.arn
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.stagelog_cdn.domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  value = aws_cloudfront_distribution.stagelog_cdn.hosted_zone_id
}
