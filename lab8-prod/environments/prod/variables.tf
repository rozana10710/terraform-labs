variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "name_suffix" {
  description = "Your initials, lowercase (used to make S3 bucket names unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,12}$", var.name_suffix))
    error_message = "name_suffix must be 2-12 characters: lowercase letters, numbers or hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for this environment's VPC"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDRs for this environment"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for this environment"
  type        = string
}

variable "subnet_index" {
  description = "Which public subnet the web server goes in (0 or 1)"
  type        = number
  default     = 0
}
