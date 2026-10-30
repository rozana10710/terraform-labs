# EC2 in the public subnet
resource "aws_instance" "public" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-public-ec2"
  }
}

# EC2 in the private subnet
resource "aws_instance" "private" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id

  tags = {
    Name = "${var.project_name}-private-ec2"
  }
}
