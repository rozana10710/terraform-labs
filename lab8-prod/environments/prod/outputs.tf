output "url" {
  description = "URL of the web server"
  value       = module.web_app.url
}

output "instance_id" {
  description = "ID of the web server"
  value       = module.web_app.instance_id
}

output "logs_bucket" {
  description = "Name of the logs bucket"
  value       = module.web_app.logs_bucket
}

output "critical_data_bucket" {
  description = "Name of the prod-only critical data bucket"
  value       = aws_s3_bucket.critical_data.id
}
