locals {
  name_prefix = "${var.project}-${var.environment}"

  # Public subnet in the first AZ, private subnet in the second
  public_az  = data.aws_availability_zones.available.names[0]
  private_az = data.aws_availability_zones.available.names[1]

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}
