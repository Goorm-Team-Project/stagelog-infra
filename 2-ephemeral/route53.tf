data "aws_route53_zone" "main" {
  name         = "pearlinvest.click"
  private_zone = false
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "pearlinvest.click"
  type    = "A"

  allow_overwrite = true

  alias {
    name                   = local.cloudfront_distribution_domain_name
    zone_id                = local.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.pearlinvest.click"
  type    = "A"

  allow_overwrite = true

  alias {
    name                   = local.cloudfront_distribution_domain_name
    zone_id                = local.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}
