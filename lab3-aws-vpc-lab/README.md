# AWS VPC Lab — Public/Private Subnets, EC2, EBS and a Public S3 Bucket

## What it builds

```
                           Internet
                              │
                     ┌────────┴────────┐
                     │ Internet Gateway│
                     └────────┬────────┘
┌─────────────── VPC 10.0.0.0/16 ─────┼──────────────────────────────┐
│                                     │                              │
│  ┌──── Public subnet 10.0.1.0/24 (AZ a) ───┐  ┌── Private subnet 10.0.2.0/24 (AZ b) ──┐
│  │  route 0.0.0.0/0 → IGW                  │  │  local routes only                     │
│  │                                         │  │  (+ 0.0.0.0/0 → NAT if enabled)        │
│  │  EC2 "public"  (public IP, httpd) ──────┼──┼─► EC2 "private" (no public IP)         │
│  │    └─ EBS data volume 1 GiB             │  │    └─ EBS data volume 1 GiB            │
│  │  [NAT Gateway — optional]               │  │                                        │
│  └─────────────────────────────────────────┘  └────────────────────────────────────────┘
└────────────────────────────────────────────────────────────────────┘

S3 bucket (outside the VPC): public read, static website with index.html
```

| Resource | Count | Notes |
|---|---|---|
| VPC, Internet Gateway | 1 each | DNS hostnames enabled |
| Subnets | 2 | Public in AZ a, private in AZ b |
| Route tables | 2 | Public → IGW; private → local only (or NAT) |
| Security groups | 2 | Public: HTTP in. Private: HTTP only from the public SG, ping from VPC |
| EC2 instances | 2 | t3.micro, AL2023, IMDSv2, encrypted root disk |
| EBS data volumes | 2 | 1 GiB gp3, encrypted, attached as /dev/sdf |
| S3 bucket | 1 | Public read via bucket policy, website hosting |
| NAT Gateway + EIP | 0 or 1 | Only when `enable_nat_gateway = true` |

## Files

| File | Contents |
|---|---|
| `terraform.tf` | Terraform and provider versions |
| `providers.tf` | AWS provider, default tags |
| `variables.tf` | All inputs |
| `locals.tf` | Name prefix, AZ choice, common tags |
| `data.tf` | AZs and latest Amazon Linux 2023 AMI |
| `vpc.tf` | VPC, IGW, subnets, route tables, optional NAT |
| `security_groups.tf` | Security groups and rules |
| `ec2.tf` | Public and private instances |
| `ebs.tf` | Data volumes and attachments |
| `s3.tf` | Public bucket, policy, website, index.html |
| `outputs.tf` | IPs, URLs, IDs |

## Run it

```bash
export AWS_PROFILE=tf_demo
aws sts get-caller-identity

cp terraform.tfvars.example terraform.tfvars   # set owner (and region)
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
```

Check the result:

- `public_web_url` — the web page from the public EC2 (wait 1–2 minutes)
- `bucket_website_url` — the page served from the public S3 bucket
- `private_instance_private_ip` — note there's **no** public IP for this one

## Important: public bucket in a managed account

If the account has **account-level S3 Block Public Access** enabled (common in
AWS Control Tower / Organizations setups), `aws_s3_bucket_policy` fails with
`AccessDenied`, even though the bucket-level settings here allow it. That's a
guardrail working as intended. Use a sandbox account where public buckets are
allowed, or ask the account owner.

Never put anything sensitive in a public bucket.

## Cost

Two t3.micro instances, ~18 GiB of gp3 storage and a tiny bucket: cents per hour.
With `enable_nat_gateway = true`, add roughly 0.05 USD per hour plus data
processing. **Always run `terraform destroy` at the end.**

## Things to try

1. **Prove the private instance is private.** In the EC2 console, the private
   instance has no public IPv4 address. Its route table has no route to the IGW.
2. **Turn on the NAT Gateway.** Set `enable_nat_gateway = true` and run
   `terraform plan`. Three resources appear (EIP, NAT, route), all created with
   `count`. Apply, then set it back to `false` and see them planned for removal.
3. **Implicit vs explicit dependencies.** Find the two `depends_on` in the code.
   Why can't Terraform work out those orders by itself?
4. **Change the web page.** Edit the `user_data` heredoc in `ec2.tf` and plan.
   Why is the instance replaced (`-/+`)?
5. **Lock down HTTP.** Set `allowed_http_cidr` to your IP `/32`. Is the change
   in-place or a replacement?
6. **Look at the graph.**
   `terraform graph | dot -Tsvg > graph.svg && open graph.svg`

## Clean up

```bash
terraform destroy
```
