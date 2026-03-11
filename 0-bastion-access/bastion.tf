locals {
  public_subnet_01 = data.terraform_remote_state.permanent.outputs.public_subnet_ids["public-01"]
  bastion_sg_id    = data.terraform_remote_state.permanent.outputs.security_groups["bastion_sg"]
}

resource "aws_iam_role" "bastion_ssm_role" {
  name = "stagelog-bastion-ssm-role-standalone"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "stagelog-bastion-ssm-role-standalone"
  }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_core" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_ssm_profile" {
  name = "stagelog-bastion-ssm-profile-standalone"
  role = aws_iam_role.bastion_ssm_role.name
}

resource "aws_instance" "stagelog_bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.public_subnet_01
  vpc_security_group_ids      = [local.bastion_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_ssm_profile.name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = var.bastion_name
  }
}
