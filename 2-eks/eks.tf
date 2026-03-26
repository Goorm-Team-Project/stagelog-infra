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
    authentication_mode                         = "API_AND_CONFIG_MAP" # API 및 ConfigMap을 통한 인증 모드
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name = "stagelog-eks"
  }
}

# 애드온(VPC CNI)
resource "aws_eks_addon" "stagelog_eks_addon" {
  cluster_name                = aws_eks_cluster.stagelog-eks.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.21.1-eksbuild.3" # EKS에서 지원하는 VPC CNI 플러그인 버전
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# 애드온(CoreDNS)
resource "aws_eks_addon" "stagelog_eks_coredns" {
  cluster_name                = aws_eks_cluster.stagelog-eks.name
  addon_name                  = "coredns"
  addon_version               = "v1.13.2-eksbuild.1" # EKS에서 지원하는 CoreDNS 플러그인 버전
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# 애드온(KubeProxy)
resource "aws_eks_addon" "stagelog_eks_kubeproxy" {
  cluster_name                = aws_eks_cluster.stagelog-eks.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.34.3-eksbuild.2" # EKS에서 지원하는 KubeProxy 플러그인 버전
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# 1. 노드용 시작 템플릿 (Managed Node Group 전용)
resource "aws_launch_template" "stagelog_node_lt" {
  name_prefix   = "stagelog-node-lt-"

  # 바로 이 부분에 보안 그룹 ID들을 리스트 형태로 넣습니다.
  vpc_security_group_ids = [
    aws_security_group.eks-node-sg.id,                         
    aws_eks_cluster.stagelog-eks.vpc_config[0].cluster_security_group_id # EKS 기본 보안 그룹 (필수!)
  ]

  # (선택) 인스턴스 타입 등 기본 설정
  instance_type = "t3.large"

  # 노드 이름 태그 설정
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "stagelog-managed-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EKS 노드 그룹(온디맨드)
resource "aws_eks_node_group" "stagelog_nodes_on_demand" {
  cluster_name    = aws_eks_cluster.stagelog-eks.name
  node_group_name = "stagelog-node-group-on-demand"
  node_role_arn   = aws_iam_role.stagelog_eks_node_group_role_managed.arn

  subnet_ids = [
    local.subnet_private_01,
    local.subnet_private_02,
  ]

  capacity_type  = "ON_DEMAND"   # 온디맨드 인스턴스 사용

  launch_template {
    id      = aws_launch_template.stagelog_node_lt.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  tags = {
    capacity_type = "ON_DEMAND"
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
  cluster_name  = aws_eks_cluster.stagelog-eks.name
  principal_arn = "arn:aws:iam::430118823715:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_AdministratorAccess_54cd6b70336b51ac"
  type          = "STANDARD"
  user_name     = "sso_admin"
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

# Karpenter가 띄운 노드가 클러스터에 '노드'로서 등록되도록 허용
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name      = aws_eks_cluster.stagelog-eks.name
  principal_arn     = local.karpenter_node_role_arn
  type              = "EC2_LINUX" # 중요: Karpenter 노드는 반드시 이 타입이어야 함
}

# 1. Karpenter 포드가 사용할 IAM Role (OIDC 연동)
resource "aws_iam_role" "karpenter_controller_role" {
  name = "karpenter-controller-role-stagelog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Condition = {
          StringEquals = {
            # "karpenter" 네임스페이스의 "karpenter" 서비스 어카운트만 이 역할을 쓸 수 있게 제한
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" : "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}

# 2. Karpenter가 EC2를 생성/삭제할 수 있는 권한 정책
resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-stagelog"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # EC2 인스턴스를 사고 팔고 태그 다는 데 필요한 최소 권한
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "iam:PassRole",
          "ssm:GetParameter",
          "pricing:GetProducts"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# 3. Role과 Policy 연결
resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}