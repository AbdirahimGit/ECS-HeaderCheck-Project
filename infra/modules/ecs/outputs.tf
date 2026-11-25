output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.headercheck_ecs_cluster.name
}

output "log_group_name" {
  description = "Name of the ECS CloudWatch log group"
  value       = aws_cloudwatch_log_group.headercheck_ecs_log_group.name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.headercheck_ecs_service.name
}