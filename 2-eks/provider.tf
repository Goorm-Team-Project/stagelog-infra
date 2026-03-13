# 쿠버네티스 프로바이더 설정
# (EKS 클러스터 리소스에서 직접 정보를 가져와서 연결합니다)
provider "kubernetes" {
  host                   = aws_eks_cluster.stagelog-eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.stagelog-eks.certificate_authority[0].data)
  
  # 실행 시점에 인증 토큰을 동적으로 가져옵니다.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.stagelog-eks.name]
    command     = "aws"
  }
}

# 헬름 프로바이더 설정
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.stagelog-eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.stagelog-eks.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.stagelog-eks.name]
      command     = "aws"
    }
  }
}