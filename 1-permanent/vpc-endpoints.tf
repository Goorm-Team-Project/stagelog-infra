data "aws_region" "current" {}

# Interface endpoint ENI용 보안그룹 (EKS private subnet 대역에서만 허용)
resource "aws_security_group" "vpce_sg" {
  name        = "stagelog-vpce-sg"
  description = "Security group for interface VPC endpoints"
  vpc_id      = aws_vpc.stagelog-vpc.id

  ingress {
    description = "HTTPS from private subnet 01"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.stagelog-subnet-private-01.cidr_block]
  }

  ingress {
    description = "HTTPS from private subnet 02"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.stagelog-subnet-private-02.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "stagelog-vpce-sg"
  }
}

# Gateway endpoint: S3
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private-rtb-01.id,
    aws_route_table.private-rtb-02.id
  ]

  tags = {
    Name = "stagelog-vpce-s3-gateway"
  }
}

# Gateway endpoint: DynamoDB
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private-rtb-01.id,
    aws_route_table.private-rtb-02.id
  ]

  tags = {
    Name = "stagelog-vpce-dynamodb-gateway"
  }
}

# Interface endpoint: SQS
resource "aws_vpc_endpoint" "sqs_interface" {
  vpc_id              = aws_vpc.stagelog-vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.stagelog-subnet-private-01.id,
    aws_subnet.stagelog-subnet-private-02.id
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-sqs-interface"
  }
}

# Interface endpoint: EventBridge
resource "aws_vpc_endpoint" "events_interface" {
  vpc_id              = aws_vpc.stagelog-vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.events"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.stagelog-subnet-private-01.id,
    aws_subnet.stagelog-subnet-private-02.id
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-events-interface"
  }
}

# Interface endpoint: CloudWatch Logs
resource "aws_vpc_endpoint" "logs_interface" {
  vpc_id              = aws_vpc.stagelog-vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.stagelog-subnet-private-01.id,
    aws_subnet.stagelog-subnet-private-02.id
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-logs-interface"
  }
}

# Interface endpoint: ECR API
resource "aws_vpc_endpoint" "ecr_api_interface" {
  vpc_id              = aws_vpc.stagelog-vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.stagelog-subnet-private-01.id,
    aws_subnet.stagelog-subnet-private-02.id
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-ecr-api-interface"
  }
}

# Interface endpoint: ECR Docker Registry
resource "aws_vpc_endpoint" "ecr_dkr_interface" {
  vpc_id              = aws_vpc.stagelog-vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.stagelog-subnet-private-01.id,
    aws_subnet.stagelog-subnet-private-02.id
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-ecr-dkr-interface"
  }
}
