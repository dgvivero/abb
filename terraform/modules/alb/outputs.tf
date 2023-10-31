# print the URL of the load balancer
output "load_balancer_ip" {
  value = aws_lb.abb_alb.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.sg_alb.id
}

output "abb_visitors_tg_arn" {
  value = aws_lb_target_group.abb_visitors_tg.arn
}