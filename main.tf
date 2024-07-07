module "vpc" {
  source = "./modules/vpc"
}

module "sg" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source = "./modules/ec2"
  frontend_subnet = module.vpc.frontend_subnet
  security_group = module.sg.security_group
  backend_subnet = module.vpc.backend_subnet
}
