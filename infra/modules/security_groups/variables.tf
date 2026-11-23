variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment for the project"
  type        = string
}

variable "alb_security_group_name" {
  description = "The name of the ALB security group"
  type        = string
  default     = "alb_security_group"
}

variable "tasks_security_group_name" {
  description = "The name of the ECS tasks security group"
  type        = string
  default     = "tasks_security_group"
}

variable "cidr_blocks_anywhere" {
  description = "CIDR blocks for allowing traffic from anywhere"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}