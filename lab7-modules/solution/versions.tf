terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
  bucket       = "tf-demo-remote-state-10710"
  key          = "terraform.tfstate"
  region       = "eu-west-1"
}
}

provider "aws" {
  region = "eu-west-1"
}
