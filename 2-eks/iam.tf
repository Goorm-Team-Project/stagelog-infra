# EKS 역할
resource "aws_iam_role" "stagelog_eks_role_managed" {
  name = "stagelog-eks-role-managed"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.stagelog_eks_role_managed.name
}

# EKS 노드 그룹 역할
resource "aws_iam_role" "stagelog_eks_node_group_role_managed" {
  name = "stagelog-eks-node-group-role-managed"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_attach_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.stagelog_eks_node_group_role_managed.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_attach_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.stagelog_eks_node_group_role_managed.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_attach_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.stagelog_eks_node_group_role_managed.name
}

# SSM Parameter Store를 읽을 수 있는 "권한 내용(Policy)"
resource "aws_iam_policy" "external_secrets" {
  name        = "StagelogExternalSecretsPolicy"
  description = "Allow ESO to read parameters from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "*" # 보안을 위해 나중에는 특정 경로(예: arn:aws:ssm:ap-northeast-2:*:parameter/dev/*)로 제한
      }
    ]
  })
}

# SSM 역할
resource "aws_iam_role" "external_secrets" {
  name = "stagelog-eso-role"

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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" : "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_attach" {
  role       = aws_iam_role.external_secrets.name 
  policy_arn = aws_iam_policy.external_secrets.arn 
}

# IAM policy for ALB Ingress Controller
resource "aws_iam_policy" "alb_ingress_controller_policy" {
  name        = "ALBIngressControllerIAMPolicy-stagelog"
  description = "IAM policy for ALB Ingress Controller to manage ALBs in EKS cluster."
  policy      = file("${path.module}/alb-ingress-controller-policy.json")
}

# IAM role for ALB Ingress Controller
resource "aws_iam_role" "alb_ingress_controller_role" {
  name               = "ALBIngressControllerIAMRole-stagelog"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity" # EKS OIDC provider를 통한 웹 아이덴티티 연동
        Effect = "Allow"
        Principal = {
            Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Condition = { 
            StringEquals = {
                "${replace(aws_eks_cluster.stagelog-eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller" 
            }
        }
      }
    ]
  })
}

# IAM policy attachment for ALB Ingress Controller
resource "aws_iam_policy_attachment" "alb_ingress_controller_policy_attachment" {
  name       = "ALBIngressControllerIAMPolicyAttachment-stagelog"
  policy_arn = aws_iam_policy.alb_ingress_controller_policy.arn
  roles      = [aws_iam_role.alb_ingress_controller_role.name]
}
