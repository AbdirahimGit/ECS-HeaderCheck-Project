variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment for the project"
  type        = string
}

variable "vpc_cidr" {
  description = "Address range for the VPC; the subnets are carved out of it as /24s"
  type        = string
}

