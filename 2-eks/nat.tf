# NAT 게이트웨이
# 1. NAT가 외부와 통신할 때 사용할 고정 IP (EIP)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "stagelog-nat-eip" }
}

# 2. NAT 게이트웨이 본체
resource "aws_nat_gateway" "stagelog-nat-gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = local.subnet_public_01

  tags = { Name = "stagelog-nat-gw" }
}

resource "aws_route" "private-nat-link-01" {
  route_table_id = local.rtb_private_01

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.stagelog-nat-gw.id
}

resource "aws_route" "private-nat-link-02" {
  route_table_id = local.rtb_private_02

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.stagelog-nat-gw.id
}