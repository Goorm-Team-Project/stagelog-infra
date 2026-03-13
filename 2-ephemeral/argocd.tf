resource "helm_release" "argocd" {

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace        = "argocd"
  create_namespace = true

  depends_on = [
    aws_eks_node_group.stagelog_nodes_spot,
    aws_eks_node_group.stagelog_nodes_on_demand,
    aws_iam_openid_connect_provider.eks # OIDC가 준비되어야 나중에 IRSA 연동이 가능
  ]

  timeout = 600
}