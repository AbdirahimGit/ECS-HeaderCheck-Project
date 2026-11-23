variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "headercheck"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}