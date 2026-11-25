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

variable "ecr_image_tag" {
  description = "Immutable image tag to deploy (Git short SHA). Never 'latest'."
  type        = string
  default     = "cbc1c6c" # a tag that really exists in ECR
}


