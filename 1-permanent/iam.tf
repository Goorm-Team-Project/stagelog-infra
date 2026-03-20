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

# GitHub Actions OIDC provider and deploy role for stagelog-auth
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
              "repo:Goorm-Team-Project/stagelog-auth:ref:refs/heads/main",
              "repo:Goorm-Team-Project/stagelog-auth:ref:refs/heads/develop",
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
