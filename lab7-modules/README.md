# Lab 4: Terraform Modules

**Time:** about 35 minutes

## Why are we doing this?

Imagine your team needs a server for **dev** and another one for **prod**.

Without modules, you copy the same code twice. If you find a mistake later,
you have to fix it in two places, and it is easy to forget one.

A **module** fixes this: you write the code **once**, in its own folder,
and use it as many times as you want.

In this lab you will:

1. **Use a module someone else wrote**: a VPC from the public Terraform Registry.
2. **Write your own module**: a small "server" module (security group + EC2 instance).
3. **Reuse your module**: create a second server with only a few extra lines.

---

## What is in this folder

```
lab7-modules/
├── README.md     <- you are here
└── solution/     <- the finished lab, if you get stuck
```

---

## Before you start

1. Go into the `starter` folder:

   ```bash
   cd starter
   ```

2. Open `versions.tf` and replace `<your-state-bucket>` with the S3 bucket
   you used for remote state in the earlier labs.
   If you use a region other than `eu-west-1`, change it here too.

3. Choose a short name for yourself, with no spaces (for example `ana`).
   You will use it in every command so your resources don't clash with
   your classmates' resources.

---

## Part 1: Use a module from the Registry (VPC)

A VPC needs many resources: subnets, route tables, an internet gateway, routes...
Instead of writing all of that, we use a ready-made module.

### Step 1.1: Create `variables.tf`

In the `starter` folder, create a file called `variables.tf`:

```hcl
variable "student_name" {
  type = string
}
```

### Step 1.2: Create `main.tf`

Create a file called `main.tf`:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name           = "lab4-${var.student_name}"
  cidr           = "10.0.0.0/16"
  azs            = ["eu-west-1a"]
  public_subnets = ["10.0.1.0/24"]
}
```

What this means:

| Line | Meaning |
|---|---|
| `module "vpc"` | We are using a module and calling it `vpc` |
| `source` | Where the module comes from (the public Terraform Registry) |
| `version` | Which version to use. **Always set this.** |
| the rest | The module's inputs (its variables) |

### Step 1.3: Run it

```bash
terraform init
```

Look at the output. You should see a line saying Terraform is **downloading**
the `terraform-aws-modules/vpc/aws` module. Every time you add a module,
you must run `terraform init` again.

```bash
terraform plan -var="student_name=<yourname>"
```

Look at the resources in the plan. They all start with `module.vpc.`.
About 10 lines of your code create several AWS resources.

```bash
terraform apply -var="student_name=<yourname>"
```

Type `yes` when asked.

### ✅ Checkpoint 1

In the AWS console, go to **VPC**. You should see a VPC called `lab4-<yourname>`.

---

## Part 2: Write your own module (server)

Now you write a module yourself. A module is just **a folder with `.tf` files**.

### Step 2.1: Create the module folder

```bash
mkdir -p modules/server
```

You will create 4 files inside `modules/server/`.

### Step 2.2: `modules/server/variables.tf`: what the module needs from you

```hcl
variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}
```

### Step 2.3: `modules/server/main.tf`: what the module creates

```hcl
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "this" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]

  tags = {
    Name = var.name
  }
}
```

Notice there is **no `provider` block** here. The module uses the provider
from the folder that calls it.

### Step 2.4: `modules/server/outputs.tf`: what the module gives back

```hcl
output "instance_id" {
  value = aws_instance.this.id
}
```

### Step 2.5: `modules/server/README.md`: how to use it

```markdown
# server module

Creates a security group and one EC2 instance.

Inputs:  name, vpc_id, subnet_id
Outputs: instance_id
```

Your module folder should now look like this:

```
modules/server/
├── README.md
├── main.tf
├── outputs.tf
└── variables.tf
```

### Step 2.6: Use your module

Go back to the `starter` folder and **add** this to the end of `main.tf`:

```hcl
module "server_dev" {
  source = "./modules/server"

  name      = "lab4-${var.student_name}-dev"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
}
```

**This is the most important part of the lab.** Look at these two lines:

```hcl
vpc_id    = module.vpc.vpc_id
subnet_id = module.vpc.public_subnets[0]
```

We take **outputs from the VPC module** and give them as **inputs to your module**.
This is how modules connect to each other.

### Step 2.7: Add an output

Create `outputs.tf` in the `starter` folder:

```hcl
output "dev_instance_id" {
  value = module.server_dev.instance_id
}
```

`module.server_dev.instance_id` reads the output your module gives back.

### Step 2.8: Run it

```bash
terraform init
terraform plan -var="student_name=<yourname>"
```

The plan should show **2 to add**: `module.server_dev.aws_security_group.this`
and `module.server_dev.aws_instance.this`.

Notice that `init` did **not** download your module. It is a local folder,
so Terraform just uses it.

```bash
terraform apply -var="student_name=<yourname>"
```

### ✅ Checkpoint 2

In the AWS console, go to **EC2 > Instances**. You should see `lab4-<yourname>-dev`.

---

## Part 3: Reuse your module

Now the payoff. Your team also needs a **prod** server.

### Step 3.1: Call the module again

Add this to the end of `main.tf`:

```hcl
module "server_prod" {
  source = "./modules/server"

  name      = "lab4-${var.student_name}-prod"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
}
```

And add this to the end of `outputs.tf`:

```hcl
output "prod_instance_id" {
  value = module.server_prod.instance_id
}
```

### Step 3.2: Run it

```bash
terraform init
terraform plan -var="student_name=<yourname>"
```

The plan should show **2 to add**: a new security group and instance for prod.
You did not copy a single resource.

```bash
terraform apply -var="student_name=<yourname>"
```

### ✅ Checkpoint 3

```bash
terraform output
```

You should see two instance IDs: one for dev and one for prod.

```bash
terraform state list
```

Every resource starts with `module.vpc.`, `module.server_dev.` or
`module.server_prod.`. That tells you which module created it.

---

## Part 4: Clean up

```bash
terraform destroy -var="student_name=<yourname>"
```

Type `yes` when asked. Always do this at the end of a lab.

---

## Common errors

| Error | Fix |
|---|---|
| `Module not installed` | You added a module but didn't run `terraform init`. Run it. |
| `Unsupported argument` | You passed something the module doesn't have as a variable. Check the spelling against `variables.tf`. |
| `Missing required argument` | You forgot one of the module's variables in the `module` block. |
| `Reference to undeclared module` | The module name doesn't match, e.g. `module.server_dev` vs `module.dev`. |

---

## What you learned

- A module is just a folder with `.tf` files.
- **Variables** are what you give a module. **Outputs** are what it gives back.
- You can use modules from the **Registry** or **write your own**.
- Always set a **version** for Registry modules.
- Run `terraform init` every time you add a module.
- Write once, use many times: fix a bug in one place and every server gets the fix.

## Quick questions

1. Why is there no `provider` block in `modules/server`?
2. What happens if you remove `version = "6.5.1"` from the VPC module?
3. You find a bug in the security group. How many files do you change to fix it for both dev and prod?
