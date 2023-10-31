#NETWOERKIG
module "networking"  {
  source = "./modules/networking"
}
module "abb_alb" {
  source = "./modules/alb"
}
module "abb_rds" {
  source = "./modules/rds"
}

# ECR repository
resource "aws_ecr_repository" "abb_repository" {
  name                 = "abb_repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# Cluster definition
resource "aws_ecs_cluster" "abb-cluster" {
  name = "abb-cluster"
}

# Task Definition
resource "aws_ecs_task_definition" "abb_task_definition" {
  family                   = "abb_app-fargate"
  container_definitions    = jsonencode([{
    name                    = "visitors-app"
    image                   = "${aws_ecr_repository.abb_repository.repository_url}:latest"
    essential               = true
    portMappings            = [{
      containerPort         = 4000
      hostPort              = 0
      protocol              = "tcp"
    }]
  }])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
}

//ECS Service SecurityGroup
resource "aws_security_group" "abb_visitor_app_task_sg" {
  name        = "abb_visitor_app_task_sg"
  vpc_id      = module.networking.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 4000
    to_port         = 4000
    security_groups = [module.abb_alb.alb_sg_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  target_group_arn = module.abb_alb.abb_visitors_tg_arn
  target_id        = aws_ecs_task_definition.abb_task_definition.id
  port             = 3000
}

resource "aws_ecs_service" "visitors-service" {
 cluster = aws_ecs_cluster.abb-cluster.id
 desired_count = var.app_count
 launch_type = "FARGATE"
 name = "visitors-service"
 task_definition = aws_ecs_task_definition.abb_task_definition.arn

 lifecycle {
  ignore_changes = [desired_count] # Allow external changes to happen without Terraform conflicts, particularly around auto-scaling.
 }

 load_balancer {
  container_name = "visitors-app"
  container_port = 4000
  target_group_arn = module.abb_alb.abb_visitors_tg_arn
 }

 network_configuration {
   security_groups = [aws_security_group.abb_visitor_app_task_sg.id]
   subnets = module.networking.subnets_private
 }
}
