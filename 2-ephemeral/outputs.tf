output "nat_gateway_id" {
  value = aws_nat_gateway.stagelog-nat-gw.id
}

output "alb_arn" {
  value = aws_lb.stagelog-dev-alb.arn
}

output "alb_dns_name" {
  value = aws_lb.stagelog-dev-alb.dns_name
}

output "alb_https_listener_arn" {
  value = aws_lb_listener.https.arn
}
