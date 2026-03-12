variable "rds_new_snapshot_identifier" {
  description = "Snapshot ARN/ID for new RDS restore"
  type        = string
}

resource "aws_db_subnet_group" "stagelog-db-subnet-group-v2" {
  name       = "stagelog-subnet-group-v2"
  subnet_ids = [aws_subnet.stagelog-subnet-private-db-2a.id, aws_subnet.stagelog-subnet-private-db-2c.id]

  tags = {
    Name = "stagelog-db-subnet-group-v2"
  }
}

# 인스턴스 (신규)
resource "aws_db_instance" "stagelog-rds-managed-v2" {
  identifier          = "stagelog-db-managed-v2"
  engine              = "mariadb"
  engine_version      = "11.8.3"
  instance_class      = "db.t4g.micro"
  snapshot_identifier = var.rds_new_snapshot_identifier

  # 스토리지
  allocated_storage = 40
  storage_type      = "gp2"
  storage_encrypted = true

  username = "admin"
  password = var.db_password #하드코딩 X

  # 네트워크
  db_subnet_group_name   = aws_db_subnet_group.stagelog-db-subnet-group-v2.name
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  publicly_accessible    = false

  # 백업
  backup_retention_period   = 1
  backup_window             = "19:41-20:11"
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "stagelog-db-v2-final-snapshot-${formatdate("YYYYMMDDHHMM", timestamp())}"

  # 유지보수
  maintenance_window = "mon:17:30-mon:18:00"

  # 성능 + 모니터링
  performance_insights_enabled = false

  # 가용성
  multi_az = false

  # 자동 버전 업그레이드
  auto_minor_version_upgrade = true
  deletion_protection        = true

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      password
    ]
  }

  tags = { Name = "stagelog-rds-db-v2" }
}

output "rds_new_endpoint" {
  description = "New RDS Endpoint Address:Port"
  value       = aws_db_instance.stagelog-rds-managed-v2.endpoint
}

output "rds_new_address" {
  description = "New RDS Address"
  value       = aws_db_instance.stagelog-rds-managed-v2.address
}
