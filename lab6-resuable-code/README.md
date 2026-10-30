# Lab 3: Making code reusable

**Time:** ~30 min

## The scenario

Your team needs a small, repeatable environment for an app:

* a **web server** (EC2) using the latest Amazon Linux image
* **storage buckets** for logs, uploads and backups
* a **CPU alarm**, but only in **prod**
* an **app secret** that must never be written in the code

Same code, different environments. That is what variables, locals and loops are for.

## Where each topic appears

| Topic | Where to look |
|---|---|
| Variables, types, defaults, validation | `variables.tf` |
| Values for variables | `terraform.tfvars` |
| Locals | `main.tf` → `locals` block |
| Data sources (AMI + secret) | `main.tf` → `data` blocks |
| `for_each` | `main.tf` → `aws_s3_bucket.this` |
| `count` + conditional | `main.tf` → `aws_cloudwatch_metric_alarm.cpu_high` |
| `for` expressions, functions | `outputs.tf` |
| `sensitive` | `outputs.tf` → `app_secret` |
| `count` vs `for_each` | `extras/count_demo.tf` |

Read the files in this order: `variables.tf` → `terraform.tfvars` → `main.tf` → `outputs.tf`.

---

## Step 0: Setup (3 min)

1. In `backend.tf`, replace `REPLACE-WITH-YOUR-STATE-BUCKET` with the state bucket from the previous lab. The key `lab3/terraform.tfstate` keeps this lab separate.
2. In `terraform.tfvars`, change `owner` to your first name.
3. Create the secret in SSM with the AWS CLI (use your own name, lowercase):

```bash
aws ssm put-parameter \
  --name "/bootcamp-rosanna/app-secret" \
  --type SecureString \
  --value "s3cr3t-demo" \
  --region eu-west-1
```

> **Why the CLI and not Terraform?** If the secret were in a `.tf` or `.tfvars` file, it would end up in Git. Terraform only *reads* it.

---

## Step 1: Deploy (5 min)

```bash
terraform init
terraform plan
terraform apply
```

Look at the outputs:

* `ami_id`: found by the data source, not hardcoded
* `instance_type`: `t3.micro`, because we are in `dev`
* `bucket_names` and `bucket_arns`: built with `for` expressions
* `bucket_summary`: built with `length()`, `join()` and `keys()`
* `cpu_alarm`: `none`, because the alarm only exists in prod
* `app_secret`: `(sensitive value)`

---

## Step 2: Explore with `terraform console` (3 min)

```bash
terraform console
```

Try:

```
> local.common_tags
> local.is_prod
> var.buckets
> keys(var.buckets)
> [for name in keys(var.buckets) : upper(name)]
> data.aws_ami.amazon_linux.id
> aws_s3_bucket.this["logs"].bucket
> exit
```

---

## Step 3: Validation (2 min)

```bash
terraform plan -var="owner=rosanna1"
terraform plan -var="environment=test"
```

Both fail **before** contacting AWS. Mistakes are caught early.

---

## Step 4: Variable precedence + conditionals (6 min)

`terraform.tfvars` says `environment = "dev"`. Let's try to change it.

**a) Environment variable**

```bash
export TF_VAR_environment=prod
terraform plan
```

Result: **No changes.** `terraform.tfvars` is stronger than `TF_VAR_`.

**b) Command line**

```bash
terraform plan -var="environment=prod"
```

Now the plan shows:

* instance type `t3.micro` → `t3.small` (conditional in `locals`)
* **1 alarm to add** (`count` goes from 0 to 1)

`-var` is the strongest.

**c) Apply prod, then go back to dev**

```bash
terraform apply -var="environment=prod"   # check the cpu_alarm output
terraform apply                           # back to dev: alarm destroyed
unset TF_VAR_environment
```

**Precedence, weakest to strongest:**
`default` → `TF_VAR_` → `terraform.tfvars` → `*.auto.tfvars` → `-var` / `-var-file`

---

## Step 5: Sensitive values (3 min)

1. In `outputs.tf`, delete the line `sensitive = true` from `app_secret` and run `terraform plan`.
   Terraform **refuses**: values from SSM are already sensitive, so it forces you to mark the output too. Put the line back.

2. Read the value on purpose:

```bash
terraform output app_secret
```

3. Now look inside the remote state:

```bash
terraform state pull | grep s3cr3t
```

The secret is there in **plain text**.

> **Takeaway:** `sensitive` hides values from the screen, it does **not** encrypt them. Protect the state: encrypted S3 bucket, restricted access.

---

## Step 6 & 7: `count` vs `for_each` (6 min)

**Step 6: the `count` problem**

```bash
cp extras/count_demo.tf .
terraform apply
```

This creates `count_demo[0]` red, `[1]` green, `[2]` blue.

Now, in `count_demo.tf`, remove `"red"` from the list and run:

```bash
terraform plan
```

Terraform wants to **replace 2 buckets and destroy 1**, even though you only removed one. Everything shifted position: green moved to `[0]`, blue to `[1]`.

Do **not** apply. Delete the file and clean up:

```bash
rm count_demo.tf
terraform apply
```

**Step 7: the `for_each` way**

In `terraform.tfvars`, remove the `uploads` line and run:

```bash
terraform plan
```

Only `aws_s3_bucket.this["uploads"]` is destroyed. The others keep their names, so nothing else moves. Put `uploads` back.

> **Takeaway:** use `for_each` for multiple real things. Use `count` only to switch something on or off.

---

## Step 8: Clean up (2 min)

```bash
terraform destroy
aws ssm delete-parameter --name "/bootcamp-rosanna/app-secret" --region eu-west-1
```

---

## Checkpoint questions

1. Where did the AMI ID come from?
2. What is the difference between a variable and a local?
3. Why did `TF_VAR_environment=prod` not change anything?
4. Why did removing one item with `count` affect three buckets?
5. Is a `sensitive` value safe inside the state file?
