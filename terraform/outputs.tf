# print repo url
output "ecr_repository" {
  value = aws_ecr_repository.abb_repository.repository_url
}
# print the URL of the load balancer
output "load_balancer_ip" {
  value = module.abb_alb.load_balancer_ip
}

# print the URL of the load balancer
output "rds_endpoint" {
  value = module.abb_rds.rds_endpoint
}

output "ecs_sg_service" {
  description="Replace Jenkins SG with this value"
  value = aws_security_group.abb_visitor_app_task.id
}

output "repository_uri" {
  description="Replace Jenkins REPOSITORY_URI with this"
  value = aws_ecr_repository.abb_repository.repository_url
}

output "tg_arn" {
  description="Replace Jenkins APP_TG with this"
  value = module.abb_alb.abb_visitors_tg_arn
}