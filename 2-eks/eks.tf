resource "aws_eks_cluster" "stagelog-eks" {
    name     = "stagelog-eks"
    version  = "1.34"
    role_arn = aws_iam_role.stagelog_eks_role_managed.arn

    vpc_config {
        subnet_ids = [
            local.subnet_private_01,
            local.subnet_private_02,
        ]
        endpoint_private_access = true # 프라이빗 엔드포인트 액세스 활성화
        endpoint_public_access  = true # 퍼블릭 엔드포인트 액세스 활성화
    }

    access_config {
      authentication_mode = "API_AND_CONFIG_MAP" # API 및 ConfigMap을 통한 인증 모드
      bootstrap_cluster_creator_admin_permissions = true
    }
    
    tags = {
        Name = "stagelog-eks"
    }
}

# 애드온(VPC CNI)
resource "aws_eks_addon" "stagelog_eks_addon" {
    cluster_name = aws_eks_cluster.stagelog-eks.name
    addon_name   = "vpc-cni"
    addon_version = "v1.21.1-eksbuild.3" # EKS에서 지원하는 VPC CNI 플러그인 버전
    resolve_conflicts_on_create  = "OVERWRITE"
    resolve_conflicts_on_update  = "OVERWRITE"
}

# 애드온(CoreDNS)
resource "aws_eks_addon" "stagelog_eks_coredns" {
    cluster_name = aws_eks_cluster.stagelog-eks.name
    addon_name   = "coredns"
    addon_version = "v1.13.2-eksbuild.1" # EKS에서 지원하는 CoreDNS 플러그인 버전
    resolve_conflicts_on_create  = "OVERWRITE"
    resolve_conflicts_on_update  = "OVERWRITE"
}

# 애드온(KubeProxy)
resource "aws_eks_addon" "stagelog_eks_kubeproxy" {
    cluster_name = aws_eks_cluster.stagelog-eks.name
    addon_name   = "kube-proxy"
    addon_version = "v1.34.3-eksbuild.2" # EKS에서 지원하는 KubeProxy 플러그인 버전
    resolve_conflicts_on_create  = "OVERWRITE"
    resolve_conflicts_on_update  = "OVERWRITE"
}

# EKS 노드 그룹(온디맨드)
resource "aws_eks_node_group" "stagelog_nodes_on_demand" {
    cluster_name = aws_eks_cluster.stagelog-eks.name
    node_group_name = "stagelog-node-group-on-demand"
    node_role_arn = aws_iam_role.stagelog_eks_node_group_role_managed.arn

    subnet_ids = [
        local.subnet_private_01,
        local.subnet_private_02,
    ]

    instance_types = ["t3.medium"] # EC2 인스턴스 유형
    capacity_type = "ON_DEMAND" # 온디맨드 인스턴스 사용

    scaling_config {
        desired_size = 1
        max_size     = 2
        min_size     = 1
    }

    tags = {
        Name = "stagelog-node-group"
        capacity_type = "ON_DEMAND"
    }
}

# EKS 노드 그룹(스팟)
resource "aws_eks_node_group" "stagelog_nodes_spot" {
    cluster_name = aws_eks_cluster.stagelog-eks.name
    node_group_name = "stagelog-node-group-spot"
    node_role_arn = aws_iam_role.stagelog_eks_node_group_role_managed.arn

    subnet_ids = [
        local.subnet_private_01,
        local.subnet_private_02,
    ]

    instance_types = ["t3.medium"] # EC2 인스턴스 유형
    capacity_type = "SPOT" # 스팟 인스턴스 사용

    scaling_config {
        desired_size = 1
        max_size     = 2
        min_size     = 1
    }

    tags = {
        Name = "stagelog-node-group"
        capacity_type = "SPOT"
    }
}


# EKS 클러스터의 인증서(TLS) 정보 참조
data "aws_partition" "current" {}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.stagelog-eks.identity[0].oidc[0].issuer
}

# OIDC생성
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.stagelog-eks.identity[0].oidc[0].issuer
}

# 1. Access Entry 생성 (SSO 역할을 EKS에 등록)
resource "aws_eks_access_entry" "sso_admin" {
  cluster_name      = aws_eks_cluster.stagelog-eks.name
  principal_arn     = "arn:aws:iam::430118823715:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_AdministratorAccess_54cd6b70336b51ac"
  type              = "STANDARD"
  user_name         = "sso_admin"
}

# 2. Access Policy: 'system:masters'와 동일한 'ClusterAdmin' 권한 부여
resource "aws_eks_access_policy_association" "sso_admin_policy" {
  cluster_name  = aws_eks_cluster.stagelog-eks.name
  principal_arn = aws_eks_access_entry.sso_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

