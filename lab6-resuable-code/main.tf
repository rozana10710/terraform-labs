# ------------------------------------------------------------
# Provider
# ------------------------------------------------------------

provider "aws" {
  region = var.region
}

# ------------------------------------------------------------
# Locals: values WE calculate once and reuse
# ------------------------------------------------------------

locals {
  # lower() makes "Rosanna" and "rosanna" give the same names
  name_prefix = lower("${var.project}-${var.owner}")

  # true in prod, false in dev
  is_prod = var.environment == "prod"

  # conditional: bigger instance only in prod
  instance_type = local.is_prod ? "t3.small" : "t3.micro"

  # where the secret lives in SSM Parameter Store
  secret_path = "/${local.name_prefix}/app-secret"

  # tags shared by every resource
  common_tags = {
    Project     = var.project
    Owner       = lower(var.owner)
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ------------------------------------------------------------
# Data sources: READ existing information, create nothing
# ------------------------------------------------------------

# Latest Amazon Linux 2023 AMI, instead of a hardcoded ID
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# The app secret, stored in SSM (created with the AWS CLI, never in code)
data "aws_ssm_parameter" "app_secret" {
  name = local.secret_path
}

# ------------------------------------------------------------
# Resources
# ------------------------------------------------------------

# One web server
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type

  # merge() = common tags + one extra tag
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.environment}-web"
  })
}

# for_each: one bucket per entry in var.buckets, tracked by NAME
resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket = "${local.name_prefix}-${each.key}"

  tags = merge(local.common_tags, {
    Purpose = each.value
  })
}

# count + conditional: CPU alarm exists only in prod (1 = on, 0 = off)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = local.is_prod ? 1 : 0

  alarm_name          = "${local.name_prefix}-cpu-high"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  tags = local.common_tags
}
