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

output "core_api_execute_domain_name" {
  description = "Execute API domain for core REST API (for CloudFront origin)"
  value       = "${aws_api_gateway_rest_api.stagelog_core_rest_api.id}.execute-api.${var.aws_region}.amazonaws.com"
}

output "core_api_stage_name" {
  description = "Stage name for core REST API (for CloudFront origin path)"
  value       = aws_api_gateway_stage.stagelog_core_rest_stage.stage_name
}
