provider "aws" {
  region = "eu-west-1" # change to the region your trainer gives you

  default_tags {
    tags = {
      Course    = "terraform-bootcamp"
      ManagedBy = "terraform"
    }
  }
}

## IMPORTING RESOURCES

# resource "aws_s3_bucket" "imported" {
#  bucket = "import-bucket-123412345"
#}

# import {
#  to = aws_s3_bucket.imported
#  id = "import-bucket-123412345"
#}

# MOVING RESOURCES

#resource "aws_s3_bucket" "demo" {
#  bucket = "import-bucket-123412345"
#}

#moved {
#  from = aws_s3_bucket.imported
#  to   = aws_s3_bucket.demo
#}

#REMOVING RESOURCES
removed {
  from = aws_s3_bucket.demo

  lifecycle {
    destroy = false
  }
}
###########

resource "random_pet" "bucket" {
  length    = 2
  separator = "--"
}

resource "aws_s3_bucket" "lab" {
  bucket = "bootcamp-${random_pet.bucket.id}"

  # Lets "terraform destroy" delete the bucket even if it contains objects.
  # Fine for a lab — think twice before using this in real projects.
  force_destroy = true

  tags = {
    Name        = "bootcamp-${random_pet.bucket.id}"
    Environment = "prd"
    Owner       = "rosanna" # <-- change me
  }

  lifecycle {
    ignore_changes = [tags["Owner"]]
  }
}
