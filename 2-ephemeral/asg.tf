resource "aws_launch_template" "backend_lt" {
  name_prefix   = "${local.prefix}-stagelog-backend-lt-"
  image_id      = "ami-0092e0c93f74c293a"
  instance_type = "t3.micro"
  key_name      = "my-cicd-rsa"


  vpc_security_group_ids = [local.backend_sg]

  iam_instance_profile {
    name = local.backend_iam_role_profile
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    dnf update -y
    dnf install -y docker
    systemctl enable --now docker

    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

    usermod -aG docker ec2-user

    mkdir -p /home/ec2-user/stagelog-api/
    cd /home/ec2-user/stagelog-api/

    aws ssm get-parameter \
        --name "/stagelog/backend/.env" \
        --with-decryption \
        --region ap-northeast-2 \
        --query "Parameter.Value" \
        --output text > .env

    aws ssm get-parameter \
        --name "/stagelog/backend/docker-compose.yaml" \
        --with-decryption \
        --region ap-northeast-2 \
        --query "Parameter.Value" \
        --output text > docker-compose.yaml
    
    
    export AWS_ACCOUNT_ID="430118823715"
    aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com

    docker-compose pull
    docker-compose up -d

    chown -R ec2-user:ec2-user /home/ec2-user/stagelog-api
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.prefix}-stagelog-ec2-backend"
    }
  }
}

resource "aws_autoscaling_group" "backende_asg" {
  name             = "${local.prefix}-stagelog-backend-asg"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = [local.subnet_private_01]

  # 기존의 대상 그룹(Target Group)과 연결합니다.
  target_group_arns = [aws_lb_target_group.backend_tg.arn]

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  # 인스턴스가 생성될 때까지 기다리는 시간 (초)
  health_check_type         = "ELB"
  health_check_grace_period = 300
}

resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "${local.prefix}-stagelog-frontend-lt-"
  image_id      = "ami-0092e0c93f74c293a"
  instance_type = "t3.micro"
  key_name      = "my-cicd-rsa"


  vpc_security_group_ids = [local.frontend_sg]

  iam_instance_profile {
    name = local.frontend_iam_role_profile
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    dnf update -y
    dnf install -y docker
    systemctl enable --now docker

    usermod -aG docker ec2-user

    mkdir -p /home/ec2-user/stagelog-frontend/
    cd /home/ec2-user/stagelog-frontend/    
    
    export AWS_ACCOUNT_ID="430118823715"
    export AWS_REGION="ap-northeast-2"
    export ECR_IMAGE_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/stagelog/frontend:latest"

    aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com

    docker stop stagelog-frontend || true
    docker rm stagelog-frontend || true

    docker pull $ECR_IMAGE_URL

    docker run -d --name stagelog-frontend -p 80:80 $ECR_IMAGE_URL

    chown -R ec2-user:ec2-user /home/ec2-user/stagelog-api
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.prefix}-stagelog-ec2-frontend"
    }
  }
}

resource "aws_autoscaling_group" "frontend_asg" {
  name             = "${local.prefix}-stagelog-frontend-asg"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = [local.subnet_private_01]

  # 기존의 대상 그룹(Target Group)과 연결합니다.
  target_group_arns = [aws_lb_target_group.frontend_tg.arn]

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }

  # 인스턴스가 생성될 때까지 기다리는 시간 (초)
  health_check_type         = "ELB"
  health_check_grace_period = 300
}