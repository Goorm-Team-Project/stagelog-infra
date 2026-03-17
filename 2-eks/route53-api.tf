data "aws_route53_zone" "main" {
  name         = "pearlinvest.click"
  private_zone = false
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.pearlinvest.click"
  type    = "A"

  allow_overwrite = true

  alias {
    name                   = data.aws_lb.ingress_controller_alb.dns_name
    zone_id                = data.aws_lb.ingress_controller_alb.zone_id
    evaluate_target_health = true
  }
}
