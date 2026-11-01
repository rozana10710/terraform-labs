terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "lab" {

  bucket = "bootcamp-rosanna-lab145398471386484314"
  tags = {
    Environment = "dev"
    Owner       = "test" # <-- change me
  }
}



output "bucket_name" {
  value = aws_s3_bucket.lab.bucket
}
