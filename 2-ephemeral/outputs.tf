output "nat_gateway_id" {
  value = aws_nat_gateway.stagelog-nat-gw.id
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
