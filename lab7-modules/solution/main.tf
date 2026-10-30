module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name           = "lab7-${var.student_name}"
  cidr           = "10.0.0.0/16"
  azs            = ["eu-west-1a"]
  public_subnets = ["10.0.1.0/24"]
}

module "server_dev" {
  source = "./modules/server"

  name      = "lab7-${var.student_name}-dev"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
}

module "server_prod" {
  source = "./modules/server"

  name      = "lab7-${var.student_name}-prod"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
}
