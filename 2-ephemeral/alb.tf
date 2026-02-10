resource "aws_lb" "stagelog-dev-alb" {
  name               = "stagelog-${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [local.alb_sg]
  subnets            = [local.subnet_public_01, local.subnet_public_02, local.subnet_public_03]

  tags = { Name = "stagelog-alb" }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${local.prefix}-stagelog-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "${local.prefix}-stagelog-backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30

  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.stagelog-dev-alb.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type = "redirect"

    target_group_arn = null

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.stagelog-dev-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" 
  certificate_arn   = "arn:aws:acm:ap-northeast-2:430118823715:certificate/5a984177-ce59-45c6-a959-b2ce8856e67f"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/admin/"]
    }
  }
}