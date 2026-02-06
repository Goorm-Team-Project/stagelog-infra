resource "aws_cloudfront_origin_access_control" "uploads_oac" {
  name                              = "stagelog-uploads-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  tags = { Name = "stagelog-cloudfront-oac" }
}

resource "aws_cloudfront_distribution" "uploads_cdn" {
  enabled = true

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
}
