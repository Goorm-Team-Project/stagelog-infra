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
}

resource "aws_iam_role_policy_attachment" "rds_lambda_attach_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.stagelog_rds_lambda_role_managed.name
}

resource "aws_iam_role_policy_attachment" "rds_lambda_attach_vpc_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.stagelog_rds_lambda_role_managed.name
}

# GitHub Actions OIDC provider and deploy roles
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github_actions_oidc.certificates[0].sha1_fingerprint,
  ]
}

resource "aws_iam_role" "stagelog_auth_github_actions_role" {
  name = "stagelog-auth-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubActionsOidcTrustForStagelogAuth"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Goorm-Team-Project/stagelog-auth-user:ref:refs/heads/main",
              "repo:Goorm-Team-Project/stagelog-auth-user:ref:refs/heads/develop",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "stagelog_auth_github_actions_lambda_deploy" {
  name = "stagelog-auth-github-actions-lambda-deploy"
  role = aws_iam_role.stagelog_auth_github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UpdateAuthLambdaCode"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
        ]
        Resource = [
          "arn:aws:lambda:ap-northeast-2:${data.aws_caller_identity.current.account_id}:function:stagelog-auth-api",
          "arn:aws:lambda:ap-northeast-2:${data.aws_caller_identity.current.account_id}:function:stagelog-auth-authorizer",
        ]
      }
    ]
  })
}

resource "aws_iam_role" "stagelog_backend_github_actions_ecr_role" {
  name = "stagelog-backend-github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubActionsOidcTrustForBackendRepos"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Goorm-Team-Project/stagelog-auth-user:ref:refs/heads/main",
              "repo:Goorm-Team-Project/stagelog-auth-user:ref:refs/heads/develop",
              "repo:Goorm-Team-Project/stagelog-events:ref:refs/heads/main",
              "repo:Goorm-Team-Project/stagelog-events:ref:refs/heads/develop",
              "repo:Goorm-Team-Project/stagelog-posts:ref:refs/heads/main",
              "repo:Goorm-Team-Project/stagelog-posts:ref:refs/heads/develop",
              "repo:Goorm-Team-Project/stagelog-notifications:ref:refs/heads/main",
              "repo:Goorm-Team-Project/stagelog-notifications:ref:refs/heads/develop",
              "repo:Goorm-Team-Project/stagelog-outbox-worker:ref:refs/heads/main",
              "repo:Goorm-Team-Project/stagelog-outbox-worker:ref:refs/heads/develop",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "stagelog_backend_github_actions_ecr_push" {
  name = "stagelog-backend-github-actions-ecr-push"
  role = aws_iam_role.stagelog_backend_github_actions_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EcrAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Resource = "*"
      },
      {
        Sid    = "EcrRepositoryBootstrap"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
        ]
        Resource = "*"
      },
      {
        Sid    = "EcrPushAndRead"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = [
          "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/stagelog-auth",
          "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/stagelog-events",
          "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/stagelog-posts",
          "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/stagelog-notifications",
          "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/stagelog-outbox-worker",
        ]
      }
    ]
  })
}

resource "aws_iam_role" "stagelog_karpenter_node_role" {
  name = "stagelog-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "stagelog_karpenter_node_role_policy_attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # 트러블슈팅용 SSM 허용
  ])

  role       = aws_iam_role.stagelog_karpenter_node_role.name
  policy_arn = each.value
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
