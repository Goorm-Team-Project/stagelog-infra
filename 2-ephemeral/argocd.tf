resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.7"
  namespace        = "argocd"
  create_namespace = true

  # 서비스를 내부 전용(ClusterIP)으로 설정
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # 이미 존재하는 Ingress Controller를 사용하도록 설정
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  # AWS Load Balancer Controller를 사용 중이라면 아래 어노테이션이 핵심
  set {
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "alb"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing" # 외부 접속 허용
  }

  # 접속할 도메인이 있다면 적어주세요. (없다면 일단 비워둬도 생성은 됨)
  # set {
  #   name  = "server.ingress.hosts[0]"
  #   value = "argo.stagelog.com"
  # }
  
  # ArgoCD 서버가 TLS 없이(HTTP로) 통신할 수 있게 허용 (ALB가 대신 처리하므로)
  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }

  # [중요] 노드 그룹이 생성된 후에 ArgoCD를 설치하도록 순서를 고정합니다.
  # 노드가 없으면 ArgoCD Pod가 Pending 상태에서 넘어가지 않음.
  depends_on = [
    aws_eks_node_group.stagelog_nodes_on_demand,
    aws_eks_node_group.stagelog_nodes_spot
    aws_iam_openid_connect_provider.eks # OIDC가 준비되어야 나중에 IRSA 연동이 가능
  ]

  timeout = 600
}