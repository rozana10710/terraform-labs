terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "web_app" {
  source = "../../modules/web-app"

  project        = var.project
  environment    = "dev"
  name_suffix    = var.name_suffix
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  instance_type  = var.instance_type
  subnet_index   = var.subnet_index
}
