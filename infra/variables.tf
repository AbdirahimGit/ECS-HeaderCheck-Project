variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "headercheck"
}

variable "environment" {
  description = "The environment for the project"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

