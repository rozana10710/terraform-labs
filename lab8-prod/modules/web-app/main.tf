locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ---------------------------------------------------------------
# Public registry module: networking
# No NAT gateway, to keep the lab cheap. The web server sits in a
# public subnet.
# ---------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets = var.public_subnets

  enable_nat_gateway      = false
  map_public_ip_on_launch = true

  tags = local.tags
}

# ---------------------------------------------------------------
# Public registry module: security group
# HTTP in from anywhere, all traffic out.
# ---------------------------------------------------------------
module "web_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-web-sg"
  description = "Allow HTTP in, all traffic out"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

# ---------------------------------------------------------------
# Public registry module: S3 bucket for application logs
# force_destroy = true so the lab cleans up easily.
# ---------------------------------------------------------------
module "logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "${local.name}-logs-${var.name_suffix}"
  force_destroy = true

  versioning = {
    enabled = true
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# Our own resource: the web server.
# We write this one ourselves (instead of using the registry EC2
# module) because lifecycle rules can only be set on resources,
# not on module calls, and this lab needs them.
# ---------------------------------------------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnets[var.subnet_index]
  vpc_security_group_ids = [module.web_sg.security_group_id]

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y httpd
    echo "<h1>Hello from ${var.environment}</h1>" > /var/www/html/index.html
    systemctl enable --now httpd
  EOT

  tags = merge(local.tags, {
    Name = "${local.name}-web"
  })
}
