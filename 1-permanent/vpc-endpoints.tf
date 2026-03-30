data "aws_region" "current" {}

# Gateway endpoint: S3
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private-rtb-2a.id,
    aws_route_table.private-rtb-2c.id
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
    aws_route_table.private-rtb-2a.id,
    aws_route_table.private-rtb-2c.id
  ]

  tags = {
    Name = "stagelog-vpce-dynamodb-gateway"
  }
}
