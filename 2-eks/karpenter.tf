# 1. Karpenter 설치를 위한 Helm Release
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.7.0"

  # 1. 클러스터 이름 (필수)
  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.stagelog-eks.name
  }

  set {
    name  = "settings.aws.region"
    value = "ap-northeast-2"
  }

  # 2. 클러스터 엔드포인트 (v1.x에서 매우 중요!)
  set {
    name  = "settings.clusterEndpoint"
    value = aws_eks_cluster.stagelog-eks.endpoint # 또는 실제 URL
  }

  # 3. 인터럽션 큐 (스팟 사용 시 필수)
  set {
    name  = "settings.interruptionQueueName"
    value = "stagelog-eks-karpenter"
  }

  # IRSA 및 클러스터 설정 주입
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller_role.arn
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "1" # 또는 "100m" (0보다 커야 함)
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }

  # 중요: 노드 그룹이 준비된 후에 설치되어야 함
  depends_on = [
    aws_eks_node_group.stagelog_nodes_on_demand,
    aws_iam_role_policy_attachment.karpenter_controller_attach,
    aws_sqs_queue_policy.karpenter_interruption,
    aws_cloudwatch_event_target.karpenter_rules
  ]
}

# Metrics Server 설치
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  # 리스트 형태로 정확하게 전달
  set_list {
    name  = "args"
    value = ["--kubelet-insecure-tls", "--kubelet-preferred-address-types=InternalIP"]
  }
}