# Stretch Goal — S3 Bucket on AWS

Create an S3 bucket whose name uses a random pet, so every student gets a unique name.
(S3 bucket names must be unique across ALL AWS accounts worldwide.)

## Before you start

Make sure the AWS CLI is configured and your profile works:

```bash
export AWS_PROFILE=bootcamp          # Windows PowerShell: $env:AWS_PROFILE = "bootcamp"
aws sts get-caller-identity
```

# terraform state list


# terraform state show aws_s3_bucket.lab

workspaces:

terraform workspace new dev
terraform state list

** LAB: migrate state **

from the latest lab, add the remote state block, watch what happens when you try:

1- without a terraform init
2- with terraform init
3-terraform init -migrate-state


**state update & state import** 

1- uncomment the import block
`terraform state list`
`terraform plan/apply`
`terraform state show`

2- To remove from state?

state remove block