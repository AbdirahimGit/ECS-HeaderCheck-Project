resource "aws_security_group" "alb_security_group" {
  name        = var.alb_security_group_name
  description = "Security group for the ALB"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_sg_rule" {
  description       = "Allow HTTP traffic to the ALB"
  security_group_id = aws_security_group.alb_security_group.id

  cidr_ipv4   = var.cidr_blocks_anywhere[0]
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_sg_rule" {
  description       = "Allow HTTPS traffic to the ALB"
  security_group_id = aws_security_group.alb_security_group.id

  cidr_ipv4   = var.cidr_blocks_anywhere[0]
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb_security_group.id
  description       = "Allow all outbound traffic from the ALB"
  cidr_ipv4         = var.cidr_blocks_anywhere[0]
  ip_protocol       = "-1"
}

resource "aws_security_group" "tasks_security_group" {
  name        = var.tasks_security_group_name
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "tasks_sg_rule" {
  description       = "Allow traffic from ALB to ECS tasks"
  security_group_id = aws_security_group.tasks_security_group.id

  referenced_security_group_id = aws_security_group.alb_security_group.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tasks_outbound" {
  security_group_id = aws_security_group.tasks_security_group.id
  description       = "Allow all outbound traffic from ECS tasks"
  cidr_ipv4         = var.cidr_blocks_anywhere[0]
  ip_protocol       = "-1"

}