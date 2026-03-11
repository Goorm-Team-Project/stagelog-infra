# RDS Lambda 역할
resource "aws_iam_role" "stagelog_rds_lambda_role_managed" {
  name = "stagelog-rds-lambda-role-managed"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::430118823715:policy/service-role/AWSLambdaBasicExecutionRole-dfc0340f-2e3b-4f7c-891c-98b53cfeccec",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
}

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

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
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

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
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
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:external-secrets:external-secrets"
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