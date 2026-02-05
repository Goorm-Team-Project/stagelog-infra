resource "aws_launch_template" "backend_lt" {
  name_prefix   = "stagelog-backend-lt-"
  image_id      = "ami-092ca3ac58d9cc079"
  instance_type = "t3.micro"
  key_name      = "mykey-251114"

  
  vpc_security_group_ids = [local.backend_sg]

  iam_instance_profile = local.backend_iam_role_profile

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "stagelog-ec2-backend"
    }
  }
}

resource "aws_autoscaling_group" "backendend_asg" {
  name                = "stagelog-backend-asg"
  desired_capacity    = 2 
  max_size            = 3 
  min_size            = 1 
  
  vpc_zone_identifier = [locals.subnet_private_01,locals.subnet_private_02]

  # 기존의 대상 그룹(Target Group)과 연결합니다.
  target_group_arns   = [aws_lb_target_group.backend_tg.arn]

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  # 인스턴스가 생성될 때까지 기다리는 시간 (초)
  health_check_type         = "ELB"
  health_check_grace_period = 300
}