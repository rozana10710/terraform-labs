# =============================================================================
# PUBLIC S3 bucket — static website, readable by ANYONE on the internet.
# Only ever put non-sensitive demo content here.
# =============================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "public" {
  bucket        = "${local.name_prefix}-public-${random_id.bucket_suffix.hex}"
  force_destroy = true # lab only: lets destroy remove the bucket with objects inside

  tags = {
    Name = "${local.name_prefix}-public-bucket"
  }
}

# Step 1: switch off the bucket-level "Block Public Access" for POLICIES.
# ACLs stay blocked — public access is granted by the bucket policy only.
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Step 2: a bucket policy that lets anyone READ objects (but not list, write or delete)
data "aws_iam_policy_document" "public_read" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.public.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.public.id
  policy = data.aws_iam_policy_document.public_read.json

  # AWS rejects a public policy while Block Public Access is still on
  depends_on = [aws_s3_bucket_public_access_block.public]
}

# Step 3: static website hosting
resource "aws_s3_bucket_website_configuration" "public" {
  bucket = aws_s3_bucket.public.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.public.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-EOT
    <html>
      <body>
        <h1>${local.name_prefix} public bucket</h1>
        <p>Served from S3. Created by Terraform for ${var.owner}.</p>
      </body>
    </html>
  EOT
}
