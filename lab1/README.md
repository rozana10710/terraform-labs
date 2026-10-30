# Lab 2 — Your First Terraform Workflow

**Duration:** ~25 minutes
**Goal:** Write a small configuration, run the full `init → plan → apply → destroy` loop, read a plan, and see how Terraform reacts to changes and drift.

No cloud account is needed for the main lab. The optional stretch goal uses AWS.

---

## Prerequisites

- Terraform installed: `terraform version` should print a version (1.5 or later)
- A terminal and a text editor (VS Code with the HashiCorp Terraform extension is recommended)

## Folder layout

```
lab2-terraform-workflow/
├── README.md          ← you are here
├── .gitignore         ← what NOT to commit in a Terraform project
├── starter/           ← you work here
├── solution/          ← reference solution (try not to peek!)
└── stretch-aws/       ← optional extra exercise on AWS
```

All commands below are run from inside the `starter/` folder:

```bash
cd lab2-terraform-workflow/starter
```

---

## Step 1 — Look at the starting files (2 min)

Open `terraform.tf`. It declares the Terraform version and the two providers used in this lab:

- `hashicorp/random` generates random values (here, a random "pet name")
- `hashicorp/local` manages files on your own machine

Open `main.tf`. **It contains formatting problems and two errors on purpose.** Don't fix anything yet.

## Step 2 — Init, format, validate, fix (5 min)

```bash
terraform init
```

Look at what appeared in the folder:

```bash
ls -la
```

- `.terraform/` — downloaded provider plugins (never commit this)
- `.terraform.lock.hcl` — exact provider versions and checksums (commit this)

Now format and validate:

```bash
terraform fmt
terraform validate
```

`fmt` fixes the layout of the file. `validate` reports errors. **Fix the errors in `main.tf` and run `terraform validate` again until you see:**

```
Success! The configuration is valid.
```

> Tip: read the error messages carefully. They tell you the file, the line, and what is wrong.

## Step 3 — Plan and apply (4 min)

```bash
terraform plan
```

Before applying, answer:

- **Q1.** How many resources will be created?
- **Q2.** In what order, and how does Terraform know that order?

Now apply. Type `yes` when asked:

```bash
terraform apply
```

Check the result:

```bash
cat motd.txt          # Windows PowerShell: Get-Content motd.txt
```

## Step 4 — Inspect state (3 min)

```bash
terraform state list

```
- **Q4.** A new file called `terraform.tfstate` appeared. What is it, and should it go into Git?


## Step 6 — Change something and read the plan (3 min)

In `main.tf`, change `separator = "--"

```bash
terraform plan
```

Look for the symbols `-/+` and the comment `# forces replacement`.

- **Q6.** You changed only one resource. Why does the plan replace **two**?


## Step 7 — Simulate drift (3 min)

Delete a tag by hand

- **Q7.** What does Terraform propose, and why?

Run `terraform apply` to bring reality back in line with the code.

## Step 8 — Clean up (2 min)

```bash
terraform destroy
```


---

## Plan symbols cheat sheet

| Symbol | Meaning |
|--------|---------|
| `+`    | create |
| `~`    | update in place |
| `-`    | destroy |
| `-/+`  | destroy and recreate (replacement) |

