# EC2 - Backend
resource "aws_instance" "stagelog-backend" {
  ami                    = "ami-092ca3ac58d9cc079"
  instance_type          = "t3.micro"
  subnet_id              = local.subnet_private_01
  vpc_security_group_ids = [local.backend_sg]
  key_name               = "my-cicd-rsa"

  private_ip = "10.1.3.152"

  iam_instance_profile = local.backend_iam_role_profile

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = { Name = "stagelog-ec2-backend" }
}


# EC2 - Frontend
resource "aws_instance" "stagelog-frontend" {
  ami           = "ami-03700e6b306a66a89"
  instance_type = "t3.micro"
  subnet_id     = local.subnet_private_01

  vpc_security_group_ids = [local.frontend_sg]
  key_name               = "my-cicd-rsa"

  private_ip = "10.1.3.140"

  iam_instance_profile = local.frontend_iam_role_profile

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = { Name = "stagelog-ec2-frontend" }
}

# EC2 - Bastion Host
resource "aws_instance" "stagelog-bastion-host" {
  ami                         = "ami-0389cb4624e21c345"
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_public_01
  associate_public_ip_address = true
  key_name                    = "khs-key-pair"
  vpc_security_group_ids      = [local.bastion_sg]
  tags = {
    Name = "stagelog-ec2-bastion"
  }
}