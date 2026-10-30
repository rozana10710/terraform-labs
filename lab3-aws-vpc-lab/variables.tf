variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name, used as a prefix in resource names (lowercase, numbers, hyphens)"
  type        = string
  default     = "tf-vpc-lab"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must contain only lowercase letters, numbers and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Your name, used in the Owner tag"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for both instances"
  type        = string
  default     = "t3.micro"
}

variable "data_volume_size_gb" {
  description = "Size of the extra EBS volume attached to each instance (GiB)"
  type        = number
  default     = 1
}

variable "allowed_http_cidr" {
  description = "Who can reach the public web server. Use your IP, e.g. 203.0.113.10/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_nat_gateway" {
  description = "Give the private subnet outbound internet via a NAT Gateway (costs ~0.05 USD/hour)"
  type        = bool
  default     = false
}
