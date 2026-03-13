# OIDC provider for EKS cluster
data "aws_iam_openid_connect_provider" "eks_oidc" {
  url = replace(aws_eks_cluster.stagelog-eks.identity[0].oidc[0].issuer, "https://", "")
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
            Federated = data.aws_iam_openid_connect_provider.eks_oidc.arn
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
