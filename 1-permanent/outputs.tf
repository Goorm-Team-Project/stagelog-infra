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

# RDS is unmanaged in this stack; expose endpoint from input vars for compatibility.
output "rds_endpoint" {
  description = "RDS Endpoint Address:Port"
  value       = format("%s:%d", var.db_host, 3306)
}

output "rds_address" {
  description = "RDS Address"
  value       = var.db_host
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

# --- SQS / DLQ ---

output "notifications_queue_url" {
  description = "Main notifications SQS queue URL"
  value       = aws_sqs_queue.notifications_queue.id
}

output "notifications_queue_arn" {
  description = "Main notifications SQS queue ARN"
  value       = aws_sqs_queue.notifications_queue.arn
}

output "notifications_dlq_url" {
  description = "Notifications DLQ URL"
  value       = aws_sqs_queue.notifications_dlq.id
}

output "notifications_dlq_arn" {
  description = "Notifications DLQ ARN"
  value       = aws_sqs_queue.notifications_dlq.arn
}

output "notifications_queue_name" {
  description = "Main notifications SQS queue name"
  value       = aws_sqs_queue.notifications_queue.name
}

output "notifications_dlq_name" {
  description = "Notifications DLQ name"
  value       = aws_sqs_queue.notifications_dlq.name
}