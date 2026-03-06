output "vpc_id" {
  value = aws_vpc.stagelog-vpc.id
}

output "public_subnet_ids" {
  value = {
    public-01 = aws_subnet.stagelog-subnet-public-2a.id
    public-02 = aws_subnet.stagelog-subnet-public-2b.id
  }
}

output "private_subnet_ids" {
  value = {
    private-01 = aws_subnet.stagelog-subnet-private-2a.id
    private-02 = aws_subnet.stagelog-subnet-private-2b.id
  }
}

output "private_route_table_ids" {
  value = {
    private-rtb-01 = aws_route_table.private-rtb-2a.id
    private-rtb-02 = aws_route_table.private-rtb-2b.id
  }
}

output "security_groups" {
  value = {
    "alb_sg"      = aws_security_group.alb-sg.id
    "bastion_sg"  = aws_security_group.bastion-sg.id
  }
}

output "iam_roles" {
  value = {
    "EKS_Role" = aws_iam_role.stagelog_eks_role_managed.id
    "EKS_node_group_Role" = aws_iam_role.stagelog_eks_node_group_role_managed.id
  }
}

output "rds_endpoint" {
  description = "RDS Endpoint Address:Port"
  value       = aws_db_instance.stagelog-rds-managed.endpoint
}

output "rds_address" {
  description = "RDS Address"
  value       = aws_db_instance.stagelog-rds-managed.address
}

output "uploads_cloudfront_domain" {
  value = aws_cloudfront_distribution.uploads_cdn.domain_name
}

output "uploads_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.uploads_cdn.id
}

output "uploads_public_base_url" {
  value = "https://${aws_cloudfront_distribution.uploads_cdn.domain_name}"
}

output "uploads_bucket_name" {
  value = aws_s3_bucket.stagelog_dev_uploads_v2.bucket
}