# ------------------------------------------------------------
# Input variables: values the USER provides
# ------------------------------------------------------------

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name, used as a prefix for resource names"
  type        = string
  default     = "bootcamp"
}

variable "owner" {
  description = "Your first name, letters only (used in resource names)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z]+$", var.owner))
    error_message = "owner must contain only letters (no numbers, spaces or symbols)."
  }
}

variable "environment" {
  description = "Deployment environment: dev or prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either dev or prod."
  }
}

variable "buckets" {
  description = "Buckets to create. Key = short name, value = what it is for"
  type        = map(string)
}
