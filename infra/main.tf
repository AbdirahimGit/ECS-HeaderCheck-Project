# Calls the network module
module "network" {
  source = "./modules/network" # path to the module's folder, relative to infra/

  project_name = var.project_name # which root variable?
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ---------------------------------------------------------------------------
# moved blocks: tell Terraform these resources now live inside the module,
# so it renames them in the state instead of destroying and recreating them.
# ---------------------------------------------------------------------------

moved {
  from = aws_vpc.project_vpc                # the old address, e.g. aws_vpc.project_vpc
  to   = module.network.aws_vpc.project_vpc # the new address, starting with module.network.
}

moved {
  from = aws_subnet.subnets                # the old address, e.g. aws_subnet.subnets
  to   = module.network.aws_subnet.subnets # the new address, starting with module.network.
}

moved {
  from = aws_internet_gateway.project_igw
  to   = module.network.aws_internet_gateway.project_igw
}

moved {
  from = aws_eip.project_nat_eip
  to   = module.network.aws_eip.project_nat_eip
}

moved {
  from = aws_nat_gateway.project_nat_gw
  to   = module.network.aws_nat_gateway.project_nat_gw
}

moved {
  from = aws_route_table.public_route_table
  to   = module.network.aws_route_table.public_route_table
}

moved {
  from = aws_route_table.private_route_table_a
  to   = module.network.aws_route_table.private_route_table_a
}

moved {
  from = aws_route_table.private_route_table_b
  to   = module.network.aws_route_table.private_route_table_b
}

moved {
  from = aws_route_table_association.association_public_subnet_a
  to   = module.network.aws_route_table_association.association_public_subnet_a
}

moved {
  from = aws_route_table_association.association_public_subnet_b
  to   = module.network.aws_route_table_association.association_public_subnet_b
}

moved {
  from = aws_route_table_association.association_private_subnet_a
  to   = module.network.aws_route_table_association.association_private_subnet_a
}

moved {
  from = aws_route_table_association.association_private_subnet_b
  to   = module.network.aws_route_table_association.association_private_subnet_b
}
