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
  environment    = "prod"
  name_suffix    = var.name_suffix
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  instance_type  = var.instance_type
  subnet_index   = var.subnet_index
}

# ---------------------------------------------------------------
# Prod-only resource: business-critical data.
# This difference between environments is explicit in prod's own
# folder, not hidden behind an "if prod" condition.
# ---------------------------------------------------------------
resource "aws_s3_bucket" "critical_data" {
  bucket = "${var.project}-prod-critical-${var.name_suffix}"

  tags = {
    Project     = var.project
    Environment = "prod"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}
