resource "aws_eks_cluster" "stagelog-eks" {
    name     = "stagelog-eks"
    version  = "1.34"
    role_arn = local.eks_role

    vpc_config {
        subnet_ids = [
            local.subnet_private_01,
            local.subnet_private_02,
        ]
        endpoint_private_access = true # 프라이빗 엔드포인트 액세스 활성화
        endpoint_public_access  = true # 퍼블릭 엔드포인트 액세스 활성화
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
    node_role_arn = local.eks_node_group_role

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
    node_role_arn = local.eks_node_group_role

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




