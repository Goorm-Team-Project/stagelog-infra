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
    Name                     = "stagelog-eks"
    "karpenter.sh/discovery" = "stagelog-eks"
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
  name_prefix = "stagelog-node-lt-"

  # 바로 이 부분에 보안 그룹 ID들을 리스트 형태로 넣습니다.
  vpc_security_group_ids = [
    local.eks_node_sg_id,                                                # EKS 노드용 SG (필수!)
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

  capacity_type = "ON_DEMAND" # 온디맨드 인스턴스 사용

  launch_template {
    id      = aws_launch_template.stagelog_node_lt.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
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

resource "aws_security_group_rule" "eks_master_to_node" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"

  # 1번 폴더에서 생성한 노드 보안 그룹 ID (변수나 Data 소스로 가져오기)
  security_group_id = local.eks_node_sg_id

  # EKS 클러스터 보안 그룹을 소스로 지정 (이게 핵심!)
  source_security_group_id = aws_eks_cluster.stagelog-eks.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "node_to_cluster_api_443" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  # 대상: EKS 클러스터가 생성한 보안 그룹
  security_group_id = aws_eks_cluster.stagelog-eks.vpc_config[0].cluster_security_group_id

  # 소스: 지금 올려주신 노드 보안 그룹
  source_security_group_id = local.eks_node_sg_id

  description = "Allow nodes to communicate with the cluster API Server"
}

# Karpenter가 띄운 노드가 클러스터에 '노드'로서 등록되도록 허용
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = aws_eks_cluster.stagelog-eks.name
  principal_arn = local.karpenter_node_role_arn
  type          = "EC2_LINUX" # 중요: Karpenter 노드는 반드시 이 타입이어야 함
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
        Sid    = "Karpenter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Sid    = "ConditionalEC2Termination"
        Effect = "Allow"
        Action = "ec2:TerminateInstances"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
        Resource = "*"
      },
      {
        Sid    = "PassNodeIAMRole"
        Effect = "Allow"
        Action = "iam:PassRole"
        # 중요: 본인이 만든 Node Role의 ARN으로 지정하세요.
        Resource = local.karpenter_node_role_arn
      },
      {
        Sid      = "EKSClusterEndpointLookup"
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = aws_eks_cluster.stagelog-eks.arn
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions"
        Effect   = "Allow"
        Resource = "*"
        Action   = ["iam:CreateInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/stagelog-eks" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"      = "ap-northeast-2"
          }
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions"
        Effect   = "Allow"
        Resource = "*"
        Action   = ["iam:TagInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/stagelog-eks" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"      = "ap-northeast-2"
            "aws:RequestTag/kubernetes.io/cluster/stagelog-eks"  = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"       = "ap-northeast-2"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileActions"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/stagelog-eks" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"      = "ap-northeast-2"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Resource = "*"
        Action   = "iam:GetInstanceProfile"
      },
      {
        Sid      = "AllowUnscopedInstanceProfileListAction"
        Effect   = "Allow"
        Resource = "*"
        Action   = "iam:ListInstanceProfiles"
      }
    ]
  })
}

# 3. Role과 Policy 연결
resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}
