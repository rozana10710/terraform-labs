terraform {
  backend "s3" {
    bucket       = "REPLACE-WITH-YOUR-STATE-BUCKET"
    key          = "bootcamp/web-app/dev/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}
