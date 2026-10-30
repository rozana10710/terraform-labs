# Terraform Lab: Your First AWS Network

In this lab you use Terraform to build a small network on AWS:

- 1 VPC
- 2 subnets: one public, one private
- 1 EC2 instance in each subnet
- 1 extra disk (EBS volume) attached to each instance
- 1 public S3 bucket

```
                    Internet
                       |
               Internet Gateway
                       |
+-------------------- VPC 10.0.0.0/16 --------------------+
|                                                         |
|   Public subnet 10.0.1.0/24     Private subnet 10.0.2.0/24
|   +---------------------+       +---------------------+ |
|   |  EC2 + extra disk   |       |  EC2 + extra disk   | |
|   +---------------------+       +---------------------+ |
+---------------------------------------------------------+


---

## Before you start

You need:

- Terraform installed: `terraform version` should print a version
- AWS credentials configured with a profile

Tell Terraform which AWS profile to use, and check that it works:

```bash
export AWS_PROFILE=tf_demo
aws sts get-caller-identity
```

You should see your AWS account number.

---

## Run the lab

Open a terminal in the folder that contains `main.tf`.

**1. Initialise.** Terraform downloads the AWS provider.

```bash
terraform init
```

**2. Preview.** Terraform shows what it will create. Nothing is created yet.

```bash
terraform plan
```

Look at the last line. How many resources will be created?

**3. Create.** Type `yes` when Terraform asks.

```bash
terraform apply
```

This takes a minute or two. At the end, Terraform prints the **outputs**: the
public EC2's IP address and the bucket name.

**4. Check in the AWS console.** Make sure you're in the **Ireland (eu-west-1)** region.

- **VPC → Your VPCs**: find `lab-vpc`
- **VPC → Subnets**: find `lab-public-subnet` and `lab-private-subnet`
- **EC2 → Instances**: find `lab-public-ec2` and `lab-private-ec2`.
  Which one has a public IP address?
- **EC2 → Volumes**: find the two 1 GiB volumes, each attached to an instance
- **S3**: find the bucket whose name starts with `lab-public-`

**5. Clean up.** Type `yes` when asked. **Don't skip this step!**

```bash
terraform destroy
```

---

## Build it one piece at a time with `-target`

Normally `terraform apply` creates **everything** in `main.tf`. With `-target`,
you tell Terraform to work on **only one resource**.

You point at a resource with its **address**: `<type>.<name>`.

```hcl
resource "aws_vpc" "main" {     # address: aws_vpc.main
```

Start from a clean state (run `terraform destroy` first if you already applied).

**1. Create only the VPC.**

```bash
terraform plan  -target=aws_vpc.main     # expect: 1 to add
terraform apply -target=aws_vpc.main
```

Terraform prints a warning that targeting is in effect. That's normal. It's
reminding you that the rest of `main.tf` was skipped.

Check the console: the VPC exists, but there are no subnets or instances yet.

**2. Create only the public subnet.**

```bash
terraform apply -target=aws_subnet.public
```

Only 1 resource is added, because the VPC it needs already exists.

**3. Target an EC2 instance.**

```bash
terraform plan -target=aws_instance.private
```

Look at the plan: Terraform adds the **private subnet** too, because the
instance needs it (`subnet_id = aws_subnet.private.id`).
`-target` always brings along whatever the target depends on.

Apply it:

```bash
terraform apply -target=aws_instance.private
```

**4. Create everything else.** A normal apply, with no `-target`:

```bash
terraform apply
```

Terraform creates only what's still missing.

**5. Destroy only one thing.** `-target` works with `destroy` too:

```bash
terraform destroy -target=aws_s3_bucket.public
```

Look at the plan: it also removes blocks 14 and 15, because they belong to the
bucket and can't exist without it.

Then clean up the rest with a normal `terraform destroy`.

> **When to use `-target`:** for learning, or to fix a problem in one resource.
> Don't use it for everyday work. If you always apply pieces separately, it's
> easy to forget something and end up with infrastructure that doesn't match
> your code.

---

## What each block does

| # | Block | What it creates |
|---|---|---|
| 1 | `provider "aws"` | Tells Terraform to use AWS, in region eu-west-1 |
| 2 | `aws_vpc` | The VPC: your own private network in AWS |
| 3 | `aws_subnet` "public" | A subnet whose instances get a public IP |
| 4 | `aws_subnet` "private" | A subnet with no internet access |
| 5 | `aws_internet_gateway` | The door between the VPC and the internet |
| 6 | `aws_route_table` | A rule: "send internet traffic to the gateway" |
| 7 | `aws_route_table_association` | Applies that rule to the public subnet. **This is what makes it public** |
| 8 | `data "aws_ami"` | Finds the latest Amazon Linux image. Reads only, creates nothing |
| 9 | `aws_instance` "public" | EC2 in the public subnet |
| 10 | `aws_instance` "private" | EC2 in the private subnet |
| 11 | `aws_ebs_volume` + `aws_volume_attachment` | Extra disk for the public EC2 |
| 12 | `aws_ebs_volume` + `aws_volume_attachment` | Extra disk for the private EC2 |
| 13 | `aws_s3_bucket` | The S3 bucket. AWS adds a unique ending to its name |
| 14 | `aws_s3_bucket_public_access_block` | Turns off S3's "block public access" protection |
| 15 | `aws_s3_bucket_policy` | Lets anyone read files in the bucket |
| 16 | `output` | Prints values after `apply` |

---

## Things to notice

**Blocks refer to each other.** In block 3, the subnet says:

```hcl
vpc_id = aws_vpc.main.id
```

This means "the ID of the VPC from block 2". Terraform sees this link and
creates the VPC before the subnet. You don't have to tell it the order.

**`resource` vs `data`.**

- A `resource` block **creates** something (blocks 2 to 15).
- A `data` block only **reads** something that already exists (block 8).

**`depends_on`.** In block 15, the bucket policy uses `depends_on` to wait for
block 14. The policy doesn't refer to block 14 anywhere, so Terraform can't see
that it must wait. `depends_on` tells it.

---

## If something goes wrong

| Error | What it means |
|---|---|
| `No valid credential sources found` | Your AWS profile isn't set in this terminal. Run `export AWS_PROFILE=tf_demo` again |
| `AccessDenied` on the bucket policy (block 15) | Your AWS account blocks public buckets. That's a security setting, not a mistake in your code. Everything else is still created |
| `No configuration files` | You're in the wrong folder. `cd` into the folder with `main.tf` |
| Resources not visible in the console | Check the region in the top right: it must be **Ireland (eu-west-1)** |

---
