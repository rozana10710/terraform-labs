# 1. Provider: which cloud and which region
provider "aws" {
  region = "eu-west-1"
}

# 2. VPC: our private network in AWS
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lab-vpc"
  }
}

# 3. Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lab-public-subnet"
  }
}

# 4. Private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "lab-private-subnet"
  }
}

# 5. Internet gateway: connects the VPC to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lab-igw"
  }
}

# 6. Route table: send internet traffic to the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "lab-public-rt"
  }
}

# 7. Attach the route table to the public subnet (this is what makes it "public")
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 8. Find the latest Amazon Linux image
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 9. EC2 in the public subnet
resource "aws_instance" "public" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "lab-public-ec2" #name of the instance
  }
}

# 10. EC2 in the private subnet
resource "aws_instance" "private" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id

  tags = {
    Name = "lab-private-ec2"
  }
}

# 11. Extra disk for the public EC2
resource "aws_ebs_volume" "public" {
  availability_zone = "eu-west-1a"
  size              = 1

  tags = {
    Name = "lab-public-volume"
  }
}

resource "aws_volume_attachment" "public" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.public.id
  instance_id = aws_instance.public.id
}

# 12. Extra disk for the private EC2
resource "aws_ebs_volume" "private" {
  availability_zone = "eu-west-1a"
  size              = 1

  tags = {
    Name = "lab-private-volume"
  }
}

resource "aws_volume_attachment" "private" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.private.id
  instance_id = aws_instance.private.id
}

# 13. S3 bucket
resource "aws_s3_bucket" "public" {
  bucket_prefix = "lab-public-" # AWS adds a unique ending to the name
  force_destroy = true
}

# 14. Turn off "block public access" on the bucket
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 15. Allow anyone to read files in the bucket
resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.public.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.public.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.public] # wait for step 14 first
}

# 16. Outputs: show some values after apply
output "public_ec2_ip" {
  value = aws_instance.public.public_ip
}

output "bucket_name" {
  value = aws_s3_bucket.public.bucket
}
