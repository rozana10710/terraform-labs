provider "aws" {
  region = "eu-west-1" # change to the region your trainer gives you

  default_tags {
    tags = {
      Course    = "terraform-bootcamp"
      ManagedBy = "terraform"
    }
  }
}

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
    Environment = "dev"
    Owner       = "rosanna" # <-- change me
  }
}
