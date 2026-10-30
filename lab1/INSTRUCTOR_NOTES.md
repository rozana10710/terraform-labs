# Lab 2 — Instructor Notes and Answers

> Remove this file before handing the lab to students if you don't want them to see the answers.

## Step 2 — Errors in starter/main.tf

`terraform fmt` fixes the indentation and aligns the `=` signs.
`terraform validate` (which needs `terraform init` first, because it uses provider schemas) reports two errors:

1. **Unsupported argument `contents`.** The `local_file` argument is `content`.
2. **Reference to undeclared resource `random_pet.srv`.** The resource is named `server`, so the reference is `random_pet.server.id`.

Corrected version: `solution/main.tf`.

## Answers

- **Q1.** Two resources: `random_pet.server` and `local_file.motd`.
- **Q2.** The pet is created first, then the file. Terraform knows because `local_file.motd` references `random_pet.server.id` (implicit dependency).
- **Q3.** Yes. State records every attribute of the resources it manages, including the generated pet name.
- **Q4.** `terraform.tfstate` is Terraform's record of what it manages and the real IDs/attributes. Never commit it, never edit it by hand. It can contain secrets. Remote state is covered later in the course.
- **Q5.** No resource changes: `Plan: 0 to add, 0 to change, 0 to destroy`, plus "Changes to Outputs". Adding an output changes nothing in the infrastructure.
- **Q6.** Changing `length` forces a new pet. The pet's `id` changes, so the file's `content` changes, and any change to a `local_file` argument forces replacement. Changes cascade through references.
- **Q7.** Terraform plans to create `local_file.motd` again. During plan it refreshes state against reality, sees the file is missing (drift), and proposes to make reality match the code.

## Stretch (AWS)

- Changing a tag shows `~` (update in place). The bucket is not replaced.
- Bucket names must be globally unique, which is why the random pet is used.
- Remind students to run `terraform destroy` before leaving.

## Common issues

- "No configuration files": running commands in the wrong folder.
- Running `validate` before `init`.
- Using `=` on nested blocks, or forgetting it on arguments.
- Smart quotes pasted from slides or chat apps.
- Windows users: use `/` in paths, or `path.module`.
- Stretch: `NoCredentialProviders` / `ExpiredToken` means `AWS_PROFILE` isn't set in that terminal.
