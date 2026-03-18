# Ingress Controller managed ALB contract
# - ALB 자체는 Ingress Controller가 생성한다.
# - Terraform은 EKS 클러스터 태그 기준으로 ALB/HTTP listener를 조회해 output으로 제공한다.

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.1.0"
  namespace  = "kube-system"

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

data "aws_lbs" "ingress_controller_albs" {
  tags = {
    "elbv2.k8s.aws/cluster" = aws_eks_cluster.stagelog-eks.name
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

locals {
  target_alb_arn = one(data.aws_lbs.ingress_controller_albs.arns)
}

data "aws_lb" "ingress_controller_alb" {
  # count = length(data.aws_lbs.ingress_controller_albs.arns) > 0 ? 1 : 0
  # arn   = sort(data.aws_lbs.ingress_controller_albs.arns)[0]
  arn = local.target_alb_arn
}

data "aws_lb_listener" "ingress_http" {
  # count             = length(data.aws_lb.ingress_controller_alb) > 0 ? 1 : 0
  # load_balancer_arn = data.aws_lb.ingress_controller_alb[0].arn
  load_balancer_arn = local.target_alb_arn
  port              = 80
}

locals {
  # resolved_ingress_alb_http_listener_arn = try(data.aws_lb_listener.ingress_http[0].arn, "")
  # resolved_core_api_url                   = try("https://${data.aws_lb.ingress_controller_alb[0].dns_name}", "")
  resolved_ingress_alb_http_listener_arn = try(data.aws_lb_listener.ingress_http.arn, "")
  resolved_core_api_url                   = "http://${data.aws_lb.ingress_controller_alb.dns_name}"
}

output "alb_http_listener_arn" {
  description = "HTTP listener ARN used by API Gateway VPC Link integration."
  value       = local.resolved_ingress_alb_http_listener_arn
}

output "alb_arn" {
  description = "Ingress ALB ARN used by API Gateway VPC Link V2 integration target."
  value       = data.aws_lb.ingress_controller_alb.arn
}

output "core_api_url" {
  description = "Core API upstream URL for API Gateway HTTP proxy integration."
  value       = local.resolved_core_api_url
}
