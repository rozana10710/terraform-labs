# Remote state: use the SAME S3 bucket as the previous lab.
# Only the key changes, so this lab gets its own state file
# and does not touch the resources from earlier labs.
#
# Note: backend blocks cannot use variables, so values are written directly.
terraform {
  backend "s3" {
  bucket       = "tf-demo-remote-state-10710"
  key          = "terraform.tfstate"
  region       = "eu-west-1"
}
}
