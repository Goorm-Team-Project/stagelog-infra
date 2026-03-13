# Ingress Controller managed ALB contract
# - ALB 자체는 Terraform이 생성하지 않는다.
# - API Gateway가 필요로 하는 HTTPS listener ARN만 output으로 제공한다.

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  version = "3.1.0"
  namespace = "kube-system"

  create_namespace = false

  values = [
    yamlencode({
      clusterName = aws_eks_cluster.stagelog-eks.name
      region      = "ap-northeast-2"
      vpcId       = local.vpc_id
      serviceAccount = {
        create = true
        name   = aws_iam_role.alb_ingress_controller_role.name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.alb_ingress_controller_role.arn
        }
      }
    })
  ]

  timeout = 600

  depends_on = [aws_eks_node_group.stagelog_nodes_on_demand]
}

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
