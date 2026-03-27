data "aws_subnet" "private_01" {
  id = local.subnet_private_01
}

data "aws_subnet" "private_02" {
  id = local.subnet_private_02
}

# Interface endpoint ENI용 보안그룹 (EKS private subnet 대역에서만 허용)
resource "aws_security_group" "vpce_sg" {
  name        = "stagelog-vpce-sg"
  description = "Security group for interface VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTPS from private subnet 01"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.private_01.cidr_block]
  }

  ingress {
    description = "HTTPS from private subnet 02"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.private_02.cidr_block]
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

resource "aws_vpc_endpoint" "sqs_interface" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    local.subnet_private_01,
    local.subnet_private_02,
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-sqs-interface"
  }
}

resource "aws_vpc_endpoint" "events_interface" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.events"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    local.subnet_private_01,
    local.subnet_private_02,
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-events-interface"
  }
}

resource "aws_vpc_endpoint" "logs_interface" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    local.subnet_private_01,
    local.subnet_private_02,
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-logs-interface"
  }
}

resource "aws_vpc_endpoint" "ecr_api_interface" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    local.subnet_private_01,
    local.subnet_private_02,
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-ecr-api-interface"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr_interface" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    local.subnet_private_01,
    local.subnet_private_02,
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-ecr-dkr-interface"
  }
}

resource "aws_vpc_endpoint" "sts_interface" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    local.subnet_private_01,
    local.subnet_private_02,
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "stagelog-vpce-sts-interface"
  }
}
