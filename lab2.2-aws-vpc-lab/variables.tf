# Variables are the INPUTS of the project.
# Here we only DECLARE them (name, type, description).
# Their values are set in terraform.tfvars.
# In the code, we use them as var.<name>, for example var.region

variable "region" {
  description = "AWS region to create everything in"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the subnets and volumes"
  type        = string
}

variable "project_name" {
  description = "Prefix used in the name of every resource"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range of the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "IP range of the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "IP range of the private subnet"
  type        = string
}

variable "instance_type" {
  description = "Size of the EC2 instances"
  type        = string
  default     = "t3.micro" # used if terraform.tfvars doesn't set a value
}

variable "volume_size" {
  description = "Size of each extra disk, in GiB"
  type        = number
  default     = 1
}
