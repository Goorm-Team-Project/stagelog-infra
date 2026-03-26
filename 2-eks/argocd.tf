resource "helm_release" "argocd" {

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "global.nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = "stagelog-node-group-on-demand"
  }

# 1. Application Controller (동기화 엔진 - 대규모 리소스 감시 시 부하 증가)
  set {
    name  = "controller.resources.requests.cpu"
    value = "200m"  
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "512Mi" 
  }

  # 2. Redis (상태 캐시 - 데이터가 쌓일수록 메모리 중요)
  set {
    name  = "redis.resources.requests.cpu"
    value = "100m"  
  }
  set {
    name  = "redis.resources.requests.memory"
    value = "256Mi" 
  }

  # 3. API Server (UI 응답 속도 및 API 호출 처리)
  set {
    name  = "server.resources.requests.cpu"
    value = "100m"  
  }
  set {
    name  = "server.resources.requests.memory"
    value = "256Mi" 
  }

  # 4. Repo Server (Manifest 렌더링/Kustomize/Helm 템플릿 처리 - 부하 급증 구간)
  set {
    name  = "repoServer.resources.requests.cpu"
    value = "200m"  
  }
  set {
    name  = "repoServer.resources.requests.memory"
    value = "512Mi" 
  }

  # 5. ApplicationSet Controller (매니페스트 자동 생성)
  set {
    name  = "applicationSet.resources.requests.cpu"
    value = "100m"  
  }
  set {
    name  = "applicationSet.resources.requests.memory"
    value = "128Mi" 
  }

  # 6. Notifications Controller (알림 전송 - 비교적 가벼움)
  set {
    name  = "notifications.resources.requests.cpu"
    value = "50m"   
  }
  set {
    name  = "notifications.resources.requests.memory"
    value = "128Mi" 
  }

  # 7. Dex Server (인증)
  set {
    name  = "dex.resources.requests.cpu"
    value = "50m"   
  }
  set {
    name  = "dex.resources.requests.memory"
    value = "128Mi" 
  }

  depends_on = [
    aws_eks_node_group.stagelog_nodes_spot,
    aws_eks_node_group.stagelog_nodes_on_demand,
    aws_iam_openid_connect_provider.eks_oidc, # OIDC가 준비되어야 나중에 IRSA 연동이 가능
    helm_release.aws_load_balancer_controller
  ]

  timeout = 600
}
