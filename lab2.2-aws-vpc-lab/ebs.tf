# Extra disk for the public EC2
resource "aws_ebs_volume" "public" {
  availability_zone = var.availability_zone
  size              = var.volume_size

  tags = {
    Name = "${var.project_name}-public-volume"
  }
}

resource "aws_volume_attachment" "public" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.public.id
  instance_id = aws_instance.public.id
}

# Extra disk for the private EC2
resource "aws_ebs_volume" "private" {
  availability_zone = var.availability_zone
  size              = var.volume_size

  tags = {
    Name = "${var.project_name}-private-volume"
  }
}

resource "aws_volume_attachment" "private" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.private.id
  instance_id = aws_instance.private.id
}
