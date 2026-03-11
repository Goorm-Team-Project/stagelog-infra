# 보안 그룹 (Bastion-EC2)
resource "aws_security_group" "bastion-sg" {
  name   = "stagelog-sg-bastion"
  vpc_id = aws_vpc.stagelog-vpc.id
  tags   = { Name = "stagelog-sg-bastion" }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 보안 그룹 (ALB) Ingress 
resource "aws_security_group" "alb-sg" {
  name   = "stagelog-sg-alb"
  vpc_id = aws_vpc.stagelog-vpc.id
  tags   = { Name = "stagelog-sg-alb" }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 보안 그룹 (Lambda)
resource "aws_security_group" "lambda-sg" {
  name   = "stagelog-lambda-sg"
  vpc_id = aws_vpc.stagelog-vpc.id
  tags   = { Name = "stagelog-sg-lambda" }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 보안 그룹 (RDS)
resource "aws_security_group" "rds-sg" {
  name   = "stagelog-rds-sg"
  vpc_id = aws_vpc.stagelog-vpc.id
  tags   = { Name = "stagelog-sg-rds" }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
    description = "default"
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
    description     = "connect bastion-ec2 with rds"
  }

  # ingress {
  #   from_port       = 3306
  #   to_port         = 3306
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.backend-sg.id]
  #   description     = "backend-api"
  # }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda-sg.id]
    description     = "connect lambda with rds"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}