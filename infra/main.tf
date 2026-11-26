module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id       = module.network.vpc_id
  project_name = var.project_name
  environment  = var.environment
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
  certificate_arn   = data.aws_acm_certificate.headercheck_cert.arn
}

module "ecs" {
  source = "./modules/ecs"

  project_name                   = var.project_name
  environment                    = var.environment
  aws_region                     = var.region
  ecr_repository_url             = aws_ecr_repository.headercheck_ecr.repository_url
  ecr_image_tag                  = var.ecr_image_tag
  private_subnet_ids             = module.network.private_subnet_ids
  ecs_security_group_id          = module.security_groups.tasks_sg_id
  load_balancer_target_group_arn = module.alb.target_group_arn
}