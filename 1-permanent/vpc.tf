/*
서브넷 구성
- public 서브넷: IGW 연결, ALB 배치, NAT 배치
- private(eks) 서브넷: Worker 노드, NAT 게이트웨이 연결, 외부 통신 가능
- private(db) 서브넷: DB 서버, 외부 통신 불가
*/
resource "aws_vpc" "stagelog-vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "stagelog-vpc" }
}

resource "aws_internet_gateway" "stagelog-igw" {
  vpc_id = aws_vpc.stagelog-vpc.id
  tags   = { Name = "stagelog-igw" }
}

resource "aws_subnet" "stagelog-subnet-public-2a" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "stagelog-subnet-public-2a" }
}

# public 서브넷 2
resource "aws_subnet" "stagelog-subnet-public-2c" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-northeast-2c"
  tags              = { Name = "stagelog-subnet-public-2c" }
}

# private(eks) 서브넷 1
resource "aws_subnet" "stagelog-subnet-private-2a" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  cidr_block        = "10.1.16.0/20" # Worker Nodes가 사용할 IP 범위 (4096 IP)
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "stagelog-subnet-private-2a" }
}

# private(eks) 서브넷 2
resource "aws_subnet" "stagelog-subnet-private-2c" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  cidr_block        = "10.1.32.0/20" # Worker Nodes가 사용할 IP 범위 (4096 IP)
  availability_zone = "ap-northeast-2c"
  tags              = { Name = "stagelog-subnet-private-2c" }
}

# private(db) 서브넷 1
resource "aws_subnet" "stagelog-subnet-private-db-2a" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  cidr_block        = "10.1.100.0/24"
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "stagelog-subnet-private-db-2a" }
}

# private(db) 서브넷 2
resource "aws_subnet" "stagelog-subnet-private-db-2c" {
  vpc_id            = aws_vpc.stagelog-vpc.id
  cidr_block        = "10.1.101.0/24"
  availability_zone = "ap-northeast-2c"
  tags              = { Name = "stagelog-subnet-private-db-2c" }
}

# public 라우팅 테이블 1
resource "aws_route_table" "public-rtb-2a" {
  vpc_id = aws_vpc.stagelog-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.stagelog-igw.id
  }

  tags = { Name = "stagelog-rtb-public-2a" }
}

# public 라우팅 테이블 2
resource "aws_route_table" "public-rtb-2c" {
  vpc_id = aws_vpc.stagelog-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.stagelog-igw.id
  }

  tags = { Name = "stagelog-rtb-public-2c" }

}


# private(eks) 라우팅 테이블 1
resource "aws_route_table" "private-rtb-2a" {
  vpc_id = aws_vpc.stagelog-vpc.id

  tags = { Name = "stagelog-rtb-private-2a" }
}

# private(eks) 라우팅 테이블 2
resource "aws_route_table" "private-rtb-2c" {
  vpc_id = aws_vpc.stagelog-vpc.id

  tags = { Name = "stagelog-rtb-private-2c" }
}

# private(db) 라우팅 테이블 1
resource "aws_route_table" "private-db-rtb-2a" {
  vpc_id = aws_vpc.stagelog-vpc.id

  tags = { Name = "stagelog-rtb-private-db-2a" }
}

# private(db) 라우팅 테이블 2
resource "aws_route_table" "private-db-rtb-2c" {
  vpc_id = aws_vpc.stagelog-vpc.id

  tags = { Name = "stagelog-rtb-private-db-2c" }
}

# public 라우팅 테이블 연결 1
resource "aws_route_table_association" "public-assoc-1" {
  subnet_id      = aws_subnet.stagelog-subnet-public-2a.id
  route_table_id = aws_route_table.public-rtb-2a.id
}

# public 라우팅 테이블 연결 2
resource "aws_route_table_association" "public-assoc-2" {
  subnet_id      = aws_subnet.stagelog-subnet-public-2c.id
  route_table_id = aws_route_table.public-rtb-2c.id
}


# private(eks) 라우팅 테이블 연결 1
resource "aws_route_table_association" "private-assoc-1" {
  subnet_id      = aws_subnet.stagelog-subnet-private-2a.id
  route_table_id = aws_route_table.private-rtb-2a.id
}

# private(eks) 라우팅 테이블 연결 2
resource "aws_route_table_association" "private-assoc-2" {
  subnet_id      = aws_subnet.stagelog-subnet-private-2c.id
  route_table_id = aws_route_table.private-rtb-2c.id
}

# private(db) 라우팅 테이블 연결 1
resource "aws_route_table_association" "private-db-assoc-1" {
  subnet_id      = aws_subnet.stagelog-subnet-private-db-2a.id
  route_table_id = aws_route_table.private-db-rtb-2a.id
}

# private(db) 라우팅 테이블 연결 2
resource "aws_route_table_association" "private-db-assoc-2" {
  subnet_id      = aws_subnet.stagelog-subnet-private-db-2c.id
  route_table_id = aws_route_table.private-db-rtb-2c.id
}