resource "aws_cloudfront_origin_access_control" "uploads_oac" {
  name                              = "stagelog-uploads-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "uploads_cdn" {
  enabled = true

  origin {
    domain_name              = aws_s3_bucket.stagelog-dev-uploads-v2.bucket_regional_domain_name
    origin_id                = "uploads-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.uploads_oac.id
  }

  default_cache_behavior {
    target_origin_id       = "uploads-s3"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    # 캐시 정책 default (명시 안함),
    # 추후 CachePolicy/ResponseHeadersPolicy로 확장
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
