# S3 bucket
resource "aws_s3_bucket" "public" {
  bucket_prefix = "${var.project_name}-public-" # AWS adds a unique ending to the name
  force_destroy = true
}

# Turn off "block public access" on the bucket
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Allow anyone to read files in the bucket
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

  depends_on = [aws_s3_bucket_public_access_block.public] # wait for the block above first
}
