# Credentials come from your AWS profile (export AWS_PROFILE=...), never from code.
provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
