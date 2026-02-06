resource "aws_vpc" "stagelog-vpc" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_internet_gateway" "stagelog-igw" {
    vpc_id = aws_vpc.stagelog-vpc.id
    tags = { Name = "stagelog-igw"}
}

resource "aws_subnet" "stagelog-subnet-public-01" {
    vpc_id            = aws_vpc.stagelog-vpc.id
    cidr_block        = "10.1.1.0/24"
    availability_zone = "ap-northeast-2a"
    tags = { Name = "stagelog-subnet-public-01"}
}

# public 서브넷 2
resource "aws_subnet" "stagelog-subnet-public-02" {
    vpc_id            = aws_vpc.stagelog-vpc.id
    cidr_block        = "10.1.2.0/24"
    availability_zone = "ap-northeast-2b"
    tags = { Name = "stagelog-subnet-public-02"}
}

# public 서브넷 3
resource "aws_subnet" "stagelog-subnet-public-03" {
    vpc_id            = aws_vpc.stagelog-vpc.id
    cidr_block        = "10.1.5.0/24"
    availability_zone = "ap-northeast-2c"
    tags = { Name = "stagelog-subnet-public-03"}
}

# private 서브넷 1
resource "aws_subnet" "stagelog-subnet-private-01" {
    vpc_id            = aws_vpc.stagelog-vpc.id
    cidr_block        = "10.1.3.0/24"
    availability_zone = "ap-northeast-2a"
    tags = { Name = "stagelog-subnet-private-01"}
}

# private 서브넷 2
resource "aws_subnet" "stagelog-subnet-private-02" {
    vpc_id            = aws_vpc.stagelog-vpc.id
    cidr_block        = "10.1.4.0/24"
    availability_zone = "ap-northeast-2c"
    tags = { Name = "stagelog-subnet-private-02"}
}

# public 라우팅 테이블 1
resource "aws_route_table" "public-rtb-01" {
    vpc_id         = aws_vpc.stagelog-vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.stagelog-igw.id
    }
    
    tags = { Name = "stagelog-rtb-public-01"}
}

# public 라우팅 테이블 2
resource "aws_route_table" "public-rtb-02" {
    vpc_id         = aws_vpc.stagelog-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.stagelog-igw.id
    }
    
    tags = { Name = "stagelog-rtb-public-02"}

}

# public 라우팅 테이블 3
resource "aws_route_table" "public-rtb-03" {
    vpc_id         = aws_vpc.stagelog-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.stagelog-igw.id
    }
    
    tags = { Name = "stagelog-rtb-public-03"}

}

# private 라우팅 테이블 1
resource "aws_route_table" "private-rtb-01" {
    vpc_id         = aws_vpc.stagelog-vpc.id

    tags = { Name = "stagelog-rtb-private-01"}

}

# private 라우팅 테이블 2
resource "aws_route_table" "private-rtb-02" {
    vpc_id         = aws_vpc.stagelog-vpc.id
    
    tags = { Name = "stagelog-rtb-private-02"}

}

# public 라우팅 테이블 연결 1
resource "aws_route_table_association" "public-assoc-1" {
  subnet_id      = aws_subnet.stagelog-subnet-public-01.id
  route_table_id = aws_route_table.public-rtb-01.id
}

# public 라우팅 테이블 연결 2
resource "aws_route_table_association" "public-assoc-2" {
  subnet_id      = aws_subnet.stagelog-subnet-public-02.id
  route_table_id = aws_route_table.public-rtb-02.id
}

# public 라우팅 테이블 연결 3
resource "aws_route_table_association" "public-assoc-3" {
  subnet_id      = aws_subnet.stagelog-subnet-public-03.id
  route_table_id = aws_route_table.public-rtb-03.id
}

# private 라우팅 테이블 연결 1
resource "aws_route_table_association" "private-assoc-1" {
  subnet_id      = aws_subnet.stagelog-subnet-private-01.id
  route_table_id = aws_route_table.private-rtb-01.id
}

# private 라우팅 테이블 연결 2
resource "aws_route_table_association" "private-assoc-2" {
  subnet_id      = aws_subnet.stagelog-subnet-private-02.id
  route_table_id = aws_route_table.private-rtb-02.id
}