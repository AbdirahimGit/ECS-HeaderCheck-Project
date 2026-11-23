output "alb_sg_id" {
  description = "ID of the ALB security group (for the load balancer)"
  value       = aws_security_group.alb_security_group.id
}

output "tasks_sg_id" {
  description = "ID of the ECS tasks security group (for the ECS service)"
  value       = aws_security_group.tasks_security_group.id
}