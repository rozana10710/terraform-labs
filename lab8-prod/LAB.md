# Lab 6: Running Terraform in production

**Duration:** ~75 minutes
**Goal:** deploy the same web app to a `dev` and a `prod` environment using a directory-per-environment layout, then practise the production techniques from Part 6: environments, lifecycle rules (including `precondition` and `postcondition`), `depends_on`, `moved`, `import` and `removed`.

## What you will build

Each environment gets its own copy of:

- a **VPC** with two public subnets (registry module `terraform-aws-modules/vpc/aws`)
- a **security group** allowing HTTP (registry module `terraform-aws-modules/security-group/aws`)
- an **S3 logs bucket** (registry module `terraform-aws-modules/s3-bucket/aws`)
- an **EC2 web server** showing "Hello from dev" or "Hello from prod" (our own `aws_instance` resource)

Prod also has one extra, prod-only S3 bucket for "critical data", protected with `prevent_destroy`.

> **Why is the EC2 instance not a registry module?** Lifecycle rules (`prevent_destroy`, `create_before_destroy`, `ignore_changes`, `precondition`, `postcondition`) can only be written on a `resource` block, not on a `module` call. This lab needs them on the instance, so we write it ourselves.

## Project structure

```
infra/
├── modules/
│   └── web-app/              # shared logic, used by both environments
│       ├── versions.tf
│       ├── variables.tf
│       ├── main.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── backend.tf        # dev's own state key
│   │   ├── variables.tf
│   │   ├── main.tf           # calls ../../modules/web-app
│   │   ├── outputs.tf
│   │   └── terraform.tfvars  # dev values
│   └── prod/
│       ├── backend.tf        # prod's own state key
│       ├── variables.tf
│       ├── main.tf           # calls the module + prod-only bucket
│       ├── outputs.tf
│       └── terraform.tfvars  # prod values
└── LAB.md                    # this guide
```

Look at `dev/terraform.tfvars` and `prod/terraform.tfvars` side by side. **That is the whole difference between the environments**: different CIDRs and a bigger instance in prod. No `if prod then ...` logic anywhere.

## Prerequisites

- Terraform **1.10 or newer** (`terraform version`). Needed for `use_lockfile` in the S3 backend; `removed` blocks need 1.7+.
- AWS credentials working in your terminal (`aws sts get-caller-identity`).
- The S3 state bucket you created in the remote state lab.

**Cost:** small. No NAT gateway is created, and the instances are `t3.micro` / `t3.small`. Do Step 13 (cleanup) at the end.

---

## Step 0: Configure the lab (5 min)

1. In **both** `environments/dev/backend.tf` and `environments/prod/backend.tf`, replace `REPLACE-WITH-YOUR-STATE-BUCKET` with your state bucket name. If your bucket is not in `eu-west-1`, change `region` too.
2. In **both** `terraform.tfvars` files, set `name_suffix` to your initials in lowercase (for example `rs`). S3 bucket names are global, so this keeps yours unique. If you use a different region, change `aws_region` too.

> Notice the two backends use **different `key` values**: `.../dev/terraform.tfstate` and `.../prod/terraform.tfstate`. In a real company, prod would usually be in a separate AWS account with its own state bucket.

## Step 1: Deploy dev (8 min)

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```

During `init`, watch Terraform download the three registry modules into `.terraform/modules/`.

When the apply finishes, open the `url` output in your browser. It can take a minute or two for the web server to start. You should see **Hello from dev**.

## Step 2: Deploy prod (8 min)

```bash
cd ../prod
terraform init
terraform apply
```

Open the prod `url`. You should see **Hello from prod**.

Now open your state bucket in the AWS console and go to `bootcamp/web-app/`. You will find two separate state files: `dev/terraform.tfstate` and `prod/terraform.tfstate`.

**Checkpoint:** you are in `environments/prod`. Can you accidentally change dev from here? (No. This folder only knows about prod's state.)

## Step 3: Why we don't use workspaces for prod (5 min)

Let's see the risk of workspaces for ourselves.

```bash
cd ../dev
terraform workspace show        # default
terraform workspace new scratch
terraform workspace show        # scratch
terraform plan
```

The plan wants to **create everything again**, because the `scratch` workspace has its own, empty state. Nothing in the code or the folder name tells you which workspace you are in, and the same code and credentials work for all of them. **Do not apply.** Clean up:

```bash
terraform workspace select default
terraform workspace delete scratch
```

## Step 4: `prevent_destroy` (5 min)

Open `environments/prod/main.tf` and find the `critical_data` bucket. It has:

```hcl
lifecycle {
  prevent_destroy = true
}
```

Ask Terraform what a full destroy of prod would do:

```bash
cd ../prod
terraform plan -destroy
```

The plan **fails** with an error saying the resource has `lifecycle.prevent_destroy` set but the plan calls for it to be destroyed. Nothing is deleted.

> **Remember:** this only protects the bucket while the `lifecycle` block is in the code. If someone deletes the whole resource block, the protection goes with it.

## Step 5: `create_before_destroy` (5 min)

Some changes can't be made in place, so Terraform replaces the resource. Moving an instance to a different subnet is one of them.

1. In `environments/dev/terraform.tfvars`, change `subnet_index = 0` to `subnet_index = 1`.
2. Run `terraform plan` in `environments/dev`. Find the instance in the output: it says `-/+ destroy and then create replacement`. The old server would be deleted **before** the new one exists, which means downtime.
3. In `modules/web-app/main.tf`, add a lifecycle block at the end of the `aws_instance` resource (just before its closing `}`):

   ```hcl
     lifecycle {
       create_before_destroy = true
     }
   ```

4. Run `terraform plan` again. It now says `+/- create replacement and then destroy`.
5. **Do not apply.** Set `subnet_index` back to `0`.

> We changed the **shared module**, so this setting now applies to prod too. That is the power and the risk of shared modules: always plan and apply dev first, then prod.

## Step 6: `ignore_changes` (5 min)

1. In the AWS console, open the **dev** EC2 instance, go to **Tags**, and add a tag `Owner = <your name>`.
2. In `environments/dev`, run `terraform plan`. Terraform wants to **remove** your tag, because it isn't in the code.
3. Imagine a company tool adds this tag to every instance, and Terraform should leave it alone. Extend the lifecycle block in `modules/web-app/main.tf`:

   ```hcl
     lifecycle {
       create_before_destroy = true
       ignore_changes        = [tags, tags_all]
     }
   ```

   (`tags_all` is the AWS provider's combined view of all tags. It has to be ignored as well, or the plan still shows the drift there.)

4. Run `terraform plan` again: **No changes.**

> Use `ignore_changes` narrowly. Every ignored attribute is drift you chose not to see. For example, Terraform can no longer update tags on this instance either.

## Step 7: `depends_on`: a dependency Terraform can't see (5 min)

Terraform works out the order of creation from **references**: the instance uses `module.vpc.public_subnets`, so it waits for the subnets. But it does **not** wait for everything else in the VPC module.

Here is the hidden problem. Our `user_data` runs `dnf install -y httpd`, which needs internet access. Internet access comes from the **route to the internet gateway**, which is created inside the VPC module. Nothing the instance references depends on that route, so on a fresh deploy Terraform is free to start the instance first. If it does, the install fails and the web page never appears, even though `terraform apply` reports success.

1. In `modules/web-app/main.tf`, add `depends_on` to the `aws_instance` resource, **above** the `lifecycle` block (it is a meta-argument of the resource, not part of `lifecycle`):

   ```hcl
     depends_on = [module.vpc]
   ```

2. Run `terraform plan` in `environments/dev`: **No changes.** `depends_on` doesn't change the infrastructure, only the **order** in which Terraform creates things. You will benefit from it the next time an environment is created from scratch.

> Use `depends_on` only when there is a real dependency that no reference expresses. It makes Terraform more cautious: the instance now waits for the **whole** VPC module, and Terraform may show more values as "known after apply" in plans.

## Step 8: `precondition`: check assumptions before acting (5 min)

Our instances are `t3` types, which can only run **x86_64** images. If someone changes the AMI filter to an ARM image, AWS would reject the launch with an unclear error, halfway through an apply. A precondition catches it at **plan** time, with a clear message.

1. Add a `precondition` inside the instance's `lifecycle` block:

   ```hcl
       precondition {
         condition     = data.aws_ami.al2023.architecture == "x86_64"
         error_message = "The AMI must be x86_64, because t3 instance types only run x86_64 images."
       }
   ```

2. Run `terraform plan` in `environments/dev`: no changes, the condition is true.
3. Now break it. In the `aws_ami` data source, change `values = ["al2023-ami-2023.*-x86_64"]` to `values = ["al2023-ami-2023.*-arm64"]`.
4. Run `terraform plan`. It **fails** with your error message, and nothing is changed.
5. Change the filter back to `x86_64`.

## Step 9: `postcondition`: check the result (8 min)

A **precondition** checks inputs before Terraform acts. A **postcondition** checks the resource's **real values**, using `self`. Our security rule: the web server's root disk must be encrypted.

1. Add a `postcondition` inside the same `lifecycle` block:

   ```hcl
       postcondition {
         condition     = self.root_block_device[0].encrypted
         error_message = "The root volume of the web server must be encrypted."
       }
   ```

2. Run `terraform plan` in `environments/dev`. The instance already exists, so Terraform knows the value and checks it now. Unless your account has EBS encryption by default turned on, the plan **fails**: the existing server breaks your rule.

   > If your plan passes, your account encrypts new volumes by default. The postcondition is still useful as a guardrail; read on to see the fix anyway.

3. Fix the resource. In the `aws_instance` block, below `vpc_security_group_ids`, add:

   ```hcl
     root_block_device {
       encrypted = true
     }
   ```

4. Run `terraform plan`. Encryption can't be added to an existing disk, so the instance must be replaced. Thanks to Step 5 it shows `+/- create replacement and then destroy`.
5. Apply in dev, then in prod:

   ```bash
   terraform apply                # in environments/dev
   cd ../prod && terraform apply  # same change, from the shared module
   ```

   The public IPs change because the instances were replaced. Check the new `url` outputs.

Your lifecycle block should now look like this:

```hcl
  depends_on = [module.vpc]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags, tags_all]

    precondition {
      condition     = data.aws_ami.al2023.architecture == "x86_64"
      error_message = "The AMI must be x86_64, because t3 instance types only run x86_64 images."
    }

    postcondition {
      condition     = self.root_block_device[0].encrypted
      error_message = "The root volume of the web server must be encrypted."
    }
  }
```

> **When are postconditions checked?** As early as possible: at plan time if the value is already known (like here, for an existing instance), otherwise right after the resource is created during apply. When a postcondition fails during apply, the resource **has already been created**; Terraform stops so that nothing that depends on it is built on top of a bad result.

## Step 10: `moved`: rename without destroying (7 min)

The name `web` no longer describes the instance well; we want to call it `app`.

1. In `modules/web-app/main.tf`, rename the resource:
   `resource "aws_instance" "web"` → `resource "aws_instance" "app"`
2. In `modules/web-app/outputs.tf`, replace all three `aws_instance.web` references with `aws_instance.app`.
3. Go back to `environments/dev` (`cd ../dev`) and run `terraform plan`. It shows **1 to add, 1 to destroy**: Terraform thinks the old server is gone and a new one appeared. **Stop. Do not apply.**
4. At the end of `modules/web-app/main.tf`, add:

   ```hcl
   moved {
     from = aws_instance.web
     to   = aws_instance.app
   }
   ```

   The addresses are relative to the module, so no `module.web_app.` prefix is needed.

5. Run `terraform plan` again. It now says `module.web_app.aws_instance.web has moved to module.web_app.aws_instance.app`, with nothing to add or destroy.
6. Apply in dev, then in prod:

   ```bash
   terraform apply              # in environments/dev
   cd ../prod && terraform plan # same "has moved" message
   terraform apply
   ```

Because the `moved` block lives in the shared module, every environment that uses the module gets the rename safely.

## Step 11: `import`: adopt a ClickOps resource (8 min)

Someone created a bucket by hand in the console. We'll bring it under Terraform's management in dev.

1. In the S3 console, create a bucket named `bootcamp-dev-clickops-<your suffix>` with default settings, in the same region as your lab.
2. In `environments/dev`, create a file `imports.tf`:

   ```hcl
   import {
     to = aws_s3_bucket.clickops
     id = "bootcamp-dev-clickops-<your suffix>"
   }
   ```

   > `import` blocks must be in the **root module** (the environment folder), not inside `modules/web-app`. The `id` format differs for every resource type; check the **Import** section at the bottom of each resource's page in the AWS provider docs. For an S3 bucket, it's the bucket name.

3. Let Terraform write the resource block for you:

   ```bash
   terraform plan -generate-config-out=generated.tf
   ```

   Terraform may warn that config generation is experimental. That's expected.

4. Open `generated.tf`. It contains a `resource "aws_s3_bucket" "clickops"` block with several arguments. Clean it up so only what matters remains, and rename the file to `clickops.tf`:

   ```hcl
   resource "aws_s3_bucket" "clickops" {
     bucket = "bootcamp-dev-clickops-<your suffix>"
   }
   ```

5. Run `terraform plan`. You should see **`Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.`** If it shows changes, compare your cleaned-up block with what was generated.
6. `terraform apply`, then confirm:

   ```bash
   terraform state list | grep clickops
   ```

## Step 12: `removed`: stop managing without deleting (5 min)

The bucket is being handed over to another team's Terraform project. We must remove it from **our** state, but not delete it in AWS.

1. In `environments/dev`, delete `clickops.tf` **and** `imports.tf`. (The import has done its job. An import block pointing to a resource that no longer exists in code causes an error.)
2. Create `removed.tf`:

   ```hcl
   removed {
     from = aws_s3_bucket.clickops

     lifecycle {
       destroy = false
     }
   }
   ```

3. Run `terraform plan`. It says the bucket **will no longer be managed by Terraform**, and nothing will be destroyed.
4. `terraform apply`, then check:
   - `terraform state list | grep clickops` returns nothing
   - the bucket **still exists** in the S3 console
5. Delete `removed.tf`. It has done its job.

> Without the `removed` block, simply deleting the resource from the code would have made Terraform **destroy** the bucket.

## Step 13: Cleanup (5 min)

1. Delete the `bootcamp-dev-clickops-<your suffix>` bucket in the S3 console.
2. Destroy dev:

   ```bash
   cd infra/environments/dev
   terraform destroy
   ```

3. Destroy prod:

   ```bash
   cd ../prod
   terraform destroy
   ```

   This fails because of `prevent_destroy`, exactly as in Step 4. To really delete prod, you must make a deliberate code change: remove the `lifecycle` block from `critical_data` in `environments/prod/main.tf`, then run `terraform destroy` again.

---

## Review questions

1. Why is a separate folder (or account) per environment safer than workspaces for prod?
2. You changed the shared module. In which order do you plan and apply the environments, and why?
3. Your plan says *1 to add, 1 to destroy* after you renamed a resource. What do you do?
4. Why must `import` blocks be in the environment folder, not in the module?
5. What is the difference between deleting a resource block and replacing it with a `removed` block?
6. The instance already references the VPC module. Why did we still need `depends_on`?
7. What is the difference between a `precondition` and a `postcondition`, and why can only the postcondition use `self`?

## Troubleshooting

- **`Error acquiring the state lock` / `use_lockfile` not supported:** your Terraform is older than 1.10. Upgrade, or replace `use_lockfile = true` with the DynamoDB `dynamodb_table` setting you used in the remote state lab.
- **`BucketAlreadyExists`:** someone else has that bucket name. Change `name_suffix`.
- **The plan wants to replace the instance and you didn't change anything:** the `aws_ami` data source picks the most recent Amazon Linux image, and AWS published a new one. In real projects, teams pin the AMI or add `ami` to `ignore_changes`.
- **The URL doesn't load right after apply:** wait 1–2 minutes for the instance to finish installing the web server.
