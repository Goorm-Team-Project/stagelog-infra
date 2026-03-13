# Route53 DNS for API custom domain (opt-in via variable flag)
resource "aws_route53_record" "api_custom_domain_alias" {
  count = var.create_route53_api_record ? 1 : 0

  zone_id = var.route53_hosted_zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api_custom_domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_custom_domain.regional_zone_id
    evaluate_target_health = false
  }
}
