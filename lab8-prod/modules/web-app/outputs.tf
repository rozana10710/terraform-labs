output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "logs_bucket" {
  description = "Name of the logs bucket"
  value       = module.logs_bucket.s3_bucket_id
}

output "instance_id" {
  description = "ID of the web server"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "url" {
  description = "URL of the web server"
  value       = "http://${aws_instance.web.public_ip}"
}
