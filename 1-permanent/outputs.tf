output "vpc_id" {
  value = aws_vpc.stagelog-vpc.id
}

output "public_subnet_ids" {
  value = {
    public-01 = aws_subnet.stagelog-subnet-public-2a.id
    public-02 = aws_subnet.stagelog-subnet-public-2c.id
  }
}

output "private_subnet_ids" {
  value = {
    private-01 = aws_subnet.stagelog-subnet-private-2a.id
    private-02 = aws_subnet.stagelog-subnet-private-2c.id
  }
}

output "private_route_table_ids" {
  value = {
    private-rtb-01 = aws_route_table.private-rtb-2a.id
    private-rtb-02 = aws_route_table.private-rtb-2c.id
  }
}

output "security_groups" {
  value = {
    "alb_sg"     = aws_security_group.alb-sg.id
    "bastion_sg" = aws_security_group.bastion-sg.id
  }
}

data "aws_ssm_parameter" "shared_db_host" {
  name = "/${var.project}/${var.env}/shared/DB_HOST"
}

# RDS itself is managed outside this stack, but these compatibility outputs remain
# available by reading the shared DB host from SSM.
output "rds_endpoint" {
  description = "RDS Endpoint Address:Port"
  value       = format("%s:%d", nonsensitive(data.aws_ssm_parameter.shared_db_host.value), 3306)
}

output "rds_address" {
  description = "RDS Address"
  value       = nonsensitive(data.aws_ssm_parameter.shared_db_host.value)
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
output "auth_lambda_artifact_bucket_name" {
  description = "S3 bucket name used for auth lambda artifacts"
  value       = aws_s3_bucket.auth_lambda_artifacts.bucket
}

output "auth_github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN for auth lambda code deployments"
  value       = aws_iam_role.stagelog_auth_github_actions_role.arn
}

output "backend_github_actions_ecr_role_arn" {
  description = "GitHub Actions IAM role ARN for backend app ECR image builds and pushes"
  value       = aws_iam_role.stagelog_backend_github_actions_ecr_role.arn
}

output "redis_primary_endpoint" {
  description = "Primary endpoint address for Redis"
  value       = aws_elasticache_replication_group.stagelog_redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Reader endpoint address for Redis"
  value       = aws_elasticache_replication_group.stagelog_redis.reader_endpoint_address
}

output "redis_port" {
  description = "Redis endpoint port"
  value       = aws_elasticache_replication_group.stagelog_redis.port
}
<<<<<<< HEAD
=======

output "karpenter_node_role_arn" {
  description = "Karpenter Node Role ARN"
  value       = aws_iam_role.stagelog_karpenter_node_role.arn
}
>>>>>>> 995ea851ce5897297031a8d924b0d203a5c83dea
