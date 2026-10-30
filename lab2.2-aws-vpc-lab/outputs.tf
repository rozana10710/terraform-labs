# Values shown after apply
output "public_ec2_ip" {
  value = aws_instance.public.public_ip
}

output "bucket_name" {
  value = aws_s3_bucket.public.bucket
}
