output "nat_gateway_id" {
  value = aws_nat_gateway.stagelog-nat-gw.id
}

output "alb_arn" {
  value = aws_lb.stagelog-dev-alb.arn
}