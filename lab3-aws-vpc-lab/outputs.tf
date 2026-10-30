output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "public_instance_public_ip" {
  value = aws_instance.public.public_ip
}

output "public_web_url" {
  description = "Web server on the public instance (wait 1–2 minutes after apply)"
  value       = "http://${aws_instance.public.public_ip}"
}

output "private_instance_private_ip" {
  description = "Private instance has no public IP — only this one"
  value       = aws_instance.private.private_ip
}

output "data_volume_ids" {
  value = {
    public  = aws_ebs_volume.public_data.id
    private = aws_ebs_volume.private_data.id
  }
}

output "bucket_name" {
  value = aws_s3_bucket.public.bucket
}

output "bucket_website_url" {
  value = "http://${aws_s3_bucket_website_configuration.public.website_endpoint}"
}

output "nat_gateway_enabled" {
  value = var.enable_nat_gateway
}
