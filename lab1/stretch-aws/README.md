# Stretch Goal — S3 Bucket on AWS

Create an S3 bucket whose name uses a random pet, so every student gets a unique name.
(S3 bucket names must be unique across ALL AWS accounts worldwide.)

## Before you start

Make sure the AWS CLI is configured and your profile works:

```bash
export AWS_PROFILE=bootcamp          # Windows PowerShell: $env:AWS_PROFILE = "bootcamp"
aws sts get-caller-identity
```

**Never put access keys in `.tf` files.** Terraform reads them from your AWS profile.

## Steps

1. Open `main.tf` and set your name in the `Owner` tag, and the region your trainer gives you.
2. Run the workflow:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
```

3. Find your bucket in the AWS console (S3) and check its tags.
4. Change the `Environment` tag from `dev` to `test` and run `terraform plan`.
   - Which plan symbol do you see? Is the bucket replaced or updated in place?
5. **Always clean up:**

```bash
terraform destroy
```
