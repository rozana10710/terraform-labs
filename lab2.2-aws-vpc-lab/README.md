# Terraform Lab: AWS Network, Split Into Files, With Variables

This is the same network as the single-file lab:

- 1 VPC
- 2 subnets: one public, one private
- 1 EC2 instance in each subnet
- 1 extra disk (EBS volume) attached to each instance
- 1 public S3 bucket

The difference: the code is **split into one file per component**, like in a
real project, and the values are moved into **variables**.

---

## The files

Read them in this order. It's the order things get built.

| # | File | What's inside |
|---|---|---|
| 1 | `versions.tf` | Terraform version and the AWS provider version |
| 2 | `variables.tf` | **Declares** the variables: name, type, description |
| 3 | `terraform.tfvars` | **Sets** the values of the variables |
| 4 | `provider.tf` | AWS provider and region |
| 5 | `vpc.tf` | The VPC |
| 6 | `subnets.tf` | Public and private subnets |
| 7 | `internet_gateway.tf` | Internet gateway |
| 8 | `route_table.tf` | Route table + association (makes the public subnet public) |
| 9 | `data.tf` | Finds the latest Amazon Linux image |
| 10 | `ec2.tf` | The two EC2 instances |
| 11 | `ebs.tf` | The two extra disks and their attachments |
| 12 | `s3.tf` | Public S3 bucket |
| 13 | `outputs.tf` | Values printed after apply |

**Terraform reads all `.tf` files in the folder as if they were one big file.**
The file names are only for us humans. Terraform doesn't care which file a
block is in.

---

## How variables work

Variables take three steps:

**1. Declare it** in `variables.tf`:

```hcl
variable "instance_type" {
  description = "Size of the EC2 instances"
  type        = string
  default     = "t3.micro"
}
```

**2. Give it a value** in `terraform.tfvars`:

```hcl
instance_type = "t3.micro"
```

**3. Use it** in the code with `var.<name>`:

```hcl
resource "aws_instance" "public" {
  instance_type = var.instance_type
  ...
}
```

Inside text, use `${...}`:

```hcl
Name = "${var.project_name}-vpc"     # becomes "lab-vpc"
```

**Where does the value come from?** From weakest to strongest:

1. `default` in `variables.tf`, used only if nothing else sets a value
2. `terraform.tfvars`, loaded automatically
3. `-var` on the command line, which wins over everything

If a variable has no `default` and no value anywhere, Terraform **asks you** for it.

---

## Run the lab

```bash
export AWS_PROFILE=tf_demo
aws sts get-caller-identity

terraform init
terraform plan
terraform apply
```

Check in the AWS console (region **Ireland, eu-west-1**) that everything is
there, with names starting with `lab-`.

---

## Try it: change things with variables

Run `terraform plan` after each change and read the result. You don't need to
apply.

**1. Change a name.** In `terraform.tfvars`, set `project_name = "yourname"`.
Every resource's `Name` tag changes, but you only edited one line.

**2. Change the instance size.** In `terraform.tfvars`, set
`instance_type = "t3.small"`. Both instances change.

**3. Override from the command line.**

```bash
terraform plan -var="volume_size=2"
```

The `-var` value wins over `terraform.tfvars`. Both disks change from 1 to 2 GiB.

**4. Use the default.** Delete the `volume_size` line from `terraform.tfvars`
and run `terraform plan`. Nothing changes, because the `default = 1` in
`variables.tf` is used.

**5. Missing value.** Delete the `project_name` line from `terraform.tfvars`
and run `terraform plan`. Terraform asks you to type a value, because
`project_name` has no default.

Put back the original values when you're done.

---

## Build one piece at a time with `-target`

Targeting works the same way when the code is split into files. You use the
resource address, not the file name:

```bash
terraform apply -target=aws_vpc.main        # only the VPC (from vpc.tf)
terraform apply -target=aws_subnet.public   # only the public subnet
terraform apply                             # everything else
```

---

## If something goes wrong

| Error | What it means |
|---|---|
| `No valid credential sources found` | Your AWS profile isn't set in this terminal. Run `export AWS_PROFILE=tf_demo` again |
| `Reference to undeclared input variable` | You used `var.something` but it isn't declared in `variables.tf`. Check the spelling |
| `Value for undeclared variable` | `terraform.tfvars` sets a variable that isn't declared in `variables.tf` |
| `AccessDenied` on the bucket policy | Your AWS account blocks public buckets. That's a security setting, not a mistake in your code |
| Resources not visible in the console | Check the region in the top right: it must be **Ireland (eu-west-1)** |

---

## Clean up — don't skip this!

```bash
terraform destroy
```

Type `yes`. Everything you created is removed.
