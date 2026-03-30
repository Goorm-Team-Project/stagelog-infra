# Redis (ElastiCache) - permanent layer
# - VPC private subnet에 배치
# - 기본 단일 노드 구성

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "redis_snapshot_retention_limit" {
  description = "Daily snapshot retention days"
  type        = number
  default     = 0
}

resource "aws_security_group" "redis_sg" {
  name        = "stagelog-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.stagelog-vpc.id

  tags = {
    Name = "stagelog-sg-redis"
  }

  ingress {
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
    description = "vpc internal to redis"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "stagelog_redis_subnet_group" {
  name = "stagelog-redis-subnet-group"
  subnet_ids = [
    aws_subnet.stagelog-subnet-private-db-2a.id,
    aws_subnet.stagelog-subnet-private-db-2c.id,
  ]

  tags = {
    Name = "stagelog-redis-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "stagelog_redis" {
  replication_group_id = "stagelog-redis"
  description          = "Stagelog auth/session Redis"

  engine         = "redis"
  engine_version = var.redis_engine_version
  node_type      = var.redis_node_type
  port           = var.redis_port

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  parameter_group_name       = "default.redis7"
  subnet_group_name          = aws_elasticache_subnet_group.stagelog_redis_subnet_group.name
  security_group_ids         = [aws_security_group.redis_sg.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  snapshot_retention_limit = var.redis_snapshot_retention_limit

  tags = {
    Name = "stagelog-redis"
  }
}
