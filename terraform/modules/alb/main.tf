#NETWOERKIG
module "networking"  {
  source = "../networking"
}

resource "aws_security_group" "sg_alb" {
  name        = "abb-alb-security-group"
  vpc_id      = module.networking.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "abb_alb" {
  name            = "abb-lb"
  internal           = false
  load_balancer_type = "application"
  subnets = module.networking.subnets_private
  security_groups = [aws_security_group.sg_alb.id]
}

resource "aws_lb_target_group" "abb_visitors_tg" {
  port             = 4000
  protocol         = "HTTP"
  vpc_id           = module.networking.vpc_id
  target_type      = "ip"
  health_check {
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    path                = "/"
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "abb_visitors_listener" {
  load_balancer_arn = aws_lb.abb_alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.abb_visitors_tg.id
    type             = "forward"
  }
}