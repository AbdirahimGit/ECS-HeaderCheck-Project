output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.headercheck_proj_tg.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.headercheck_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.headercheck_alb.zone_id
}   