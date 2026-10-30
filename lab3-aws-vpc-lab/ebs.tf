# Each extra volume must be in the SAME AZ as its instance,
# so the AZ is taken from the instance instead of being repeated.

# -----------------------------------------------------------------------------
# Data volume for the public instance
# -----------------------------------------------------------------------------
resource "aws_ebs_volume" "public_data" {
  availability_zone = aws_instance.public.availability_zone
  size              = var.data_volume_size_gb
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${local.name_prefix}-public-data"
  }
}

resource "aws_volume_attachment" "public_data" {
  device_name = "/dev/sdf" # appears as /dev/nvme1n1 on Nitro instances (check with lsblk)
  volume_id   = aws_ebs_volume.public_data.id
  instance_id = aws_instance.public.id
}

# -----------------------------------------------------------------------------
# Data volume for the private instance
# -----------------------------------------------------------------------------
resource "aws_ebs_volume" "private_data" {
  availability_zone = aws_instance.private.availability_zone
  size              = var.data_volume_size_gb
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${local.name_prefix}-private-data"
  }
}

resource "aws_volume_attachment" "private_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.private_data.id
  instance_id = aws_instance.private.id
}
