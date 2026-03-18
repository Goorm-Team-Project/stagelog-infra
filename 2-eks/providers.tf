data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.stagelog-eks.name
}

# 2. 쿠버네티스 프로바이더 수정
provider "kubernetes" {
  host                   = aws_eks_cluster.stagelog-eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.stagelog-eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token # exec 대신 token 사용
}

# 3. 헬름 프로바이더 수정
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.stagelog-eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.stagelog-eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token # exec 대신 token 사용
  }
}