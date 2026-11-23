output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.project_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per AZ (for the ALB)"
  value = [
    for key, subnet in aws_subnet.subnets : subnet.id
    if local.subnets[key].type == "public"
  ]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, one per AZ (for the ECS tasks)"
  value = [
    for key, subnet in aws_subnet.subnets : subnet.id
    if local.subnets[key].type == "private"
  ]
}