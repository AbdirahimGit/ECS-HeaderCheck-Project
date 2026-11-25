variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment for the project"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
  type        = string
}

variable "ecr_image_tag" {
  description = "Immutable image tag to deploy (Git short SHA). Never 'latest'."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets, one per AZ (for the ECS tasks)"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the tasks security group (allows 8080 from the ALB only)"
  type        = string
}

variable "load_balancer_target_group_arn" {
  description = "ARN of the ALB target group (for the ECS service)"
  type        = string
}