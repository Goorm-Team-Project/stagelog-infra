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