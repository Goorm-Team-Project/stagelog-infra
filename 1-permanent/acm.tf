# ACM 인증서 생성
resource "aws_acm_certificate" "cert" {
  provider          = aws.use1
  domain_name       = "pearlinvest.click"
  validation_method = "DNS"

  subject_alternative_names = ["www.pearlinvest.click"]

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "stagelog-certificate" }
}

# Route 53 검증용 레코드 자동 생성
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.main.zone_id
}

# 인증서 발급 완료까지 대기하는 리소스
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}