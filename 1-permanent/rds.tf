resource "aws_db_subnet_group" "stagelog-db-subnet-group" {
  name       = "stagelog-subnet-group"
  subnet_ids = [aws_subnet.stagelog-subnet-private-01.id, aws_subnet.stagelog-subnet-private-02.id]

  tags = {
    Name = "stagelog-db-subnet-group"
  }
}

# 인스턴스
resource "aws_db_instance" "stagelog-rds-managed" {
  identifier          = "stagelog-db-managed"
  engine              = "mariadb"
  engine_version      = "11.8.3"
  instance_class      = "db.t4g.micro"
  snapshot_identifier = "arn:aws:rds:ap-northeast-2:430118823715:snapshot:rds:stagelog-db-2026-02-02-19-55" // 스냅샷 ID 넣고 코드 상에서는 나중에 지우기

  # 스토리지
  allocated_storage = 40
  storage_type      = "gp2"
  storage_encrypted = true

  username = "admin"
  password = var.db_password #하드코딩 X

  # 네트워크
  db_subnet_group_name   = aws_db_subnet_group.stagelog-db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  publicly_accessible    = false

  # 백업
  backup_retention_period   = 1
  backup_window             = "19:41-20:11"
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "stagelog-db-final-snapshot-${formatdate("YYYYMMDDHHMM", timestamp())}"

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

  tags = { Name = "stagelog-rds-db" }
}