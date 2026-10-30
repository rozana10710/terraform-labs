# ------------------------------------------------------------
# Outputs: values printed after apply
# ------------------------------------------------------------

output "ami_id" {
  description = "AMI found by the data source"
  value       = data.aws_ami.amazon_linux.id
}

output "instance_id" {
  value = aws_instance.web.id
}

output "instance_type" {
  description = "Changes with the environment (conditional in locals)"
  value       = aws_instance.web.instance_type
}

# for expression -> MAP: short name => real bucket name
output "bucket_names" {
  value = { for key, b in aws_s3_bucket.this : key => b.bucket }
}

# for expression -> LIST: just the ARNs
output "bucket_arns" {
  value = [for b in aws_s3_bucket.this : b.arn]
}

# functions: length(), join(), keys()
output "bucket_summary" {
  value = "${length(aws_s3_bucket.this)} buckets: ${join(", ", keys(aws_s3_bucket.this))}"
}

# conditional: show the alarm name only if it exists
output "cpu_alarm" {
  value = local.is_prod ? aws_cloudwatch_metric_alarm.cpu_high[0].alarm_name : "none (only created in prod)"
}

# sensitive: hidden in CLI output, but still plain text in state!
output "app_secret" {
  value     = data.aws_ssm_parameter.app_secret.value
  sensitive = true
}
