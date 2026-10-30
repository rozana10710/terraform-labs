# -----------------------------------------------------------------------------
# Public instance — web server with a public IP
# -----------------------------------------------------------------------------
resource "aws_instance" "public" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public.id]

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y httpd
    echo "<h1>${local.name_prefix} public server</h1><p>Owner: ${var.owner}</p>" > /var/www/html/index.html
    systemctl enable --now httpd
  EOT

  user_data_replace_on_change = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  tags = {
    Name = "${local.name_prefix}-public-ec2"
    Tier = "public"
  }

  lifecycle {
    ignore_changes = [ami] # don't replace the instance every time a new AMI is published
  }

  # The public route must exist before the instance boots, or user_data
  # can't download httpd. Nothing here references the route, so say it explicitly.
  depends_on = [aws_route.public_internet]
}

# -----------------------------------------------------------------------------
# Private instance — no public IP, not reachable from the internet
# -----------------------------------------------------------------------------
resource "aws_instance" "private" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${local.name_prefix}-private-ec2"
    Tier = "private"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
