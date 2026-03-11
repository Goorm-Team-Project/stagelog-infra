# Ingress Controller managed ALB contract
# - ALB 자체는 Terraform이 생성하지 않는다.
# - API Gateway가 필요로 하는 HTTPS listener ARN만 output으로 제공한다.

variable "ingress_alb_arn" {
  description = "Existing ingress ALB ARN (optional). Used to resolve HTTPS listener ARN when listener ARN is not provided."
  type        = string
  default     = ""
}

variable "ingress_alb_https_listener_arn" {
  description = "HTTPS listener ARN for ingress ALB. If set, takes precedence."
  type        = string
  default     = ""
}

data "aws_lb_listener" "ingress_https" {
  count = var.ingress_alb_https_listener_arn == "" && var.ingress_alb_arn != "" ? 1 : 0

  load_balancer_arn = var.ingress_alb_arn
  port              = 443
}

locals {
  resolved_ingress_alb_https_listener_arn = (
    var.ingress_alb_https_listener_arn != ""
    ? var.ingress_alb_https_listener_arn
    : try(data.aws_lb_listener.ingress_https[0].arn, "")
  )
}

output "alb_https_listener_arn" {
  description = "HTTPS listener ARN used by API Gateway VPC Link integration."
  value       = local.resolved_ingress_alb_https_listener_arn
}
