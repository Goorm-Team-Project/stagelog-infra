data "aws_route53_zone" "main" {
  name         = "pearlinvest.click"
  private_zone = false
}

resource "aws_route53_record" "root" {
  count   = aws_cloudfront_distribution.stagelog_cdn.domain_name != "" && aws_cloudfront_distribution.stagelog_cdn.hosted_zone_id != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "pearlinvest.click"
  type    = "A"

  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.stagelog_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.stagelog_cdn.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  count   = aws_cloudfront_distribution.stagelog_cdn.domain_name != "" && aws_cloudfront_distribution.stagelog_cdn.hosted_zone_id != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.pearlinvest.click"
  type    = "A"

  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.stagelog_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.stagelog_cdn.hosted_zone_id
    evaluate_target_health = true
  }
}
