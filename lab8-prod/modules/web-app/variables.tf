variable "project" {
  description = "Project name, used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "name_suffix" {
  description = "Short unique suffix (your initials) so S3 bucket names are globally unique"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets (one per AZ, two AZs)"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
}

variable "subnet_index" {
  description = "Which public subnet the web server is placed in (0 or 1)"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Extra tags added to every resource"
  type        = map(string)
  default     = {}
}
