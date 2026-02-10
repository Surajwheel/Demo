# ============================================================================
# TERRAFORM VARIABLES FOR AWS K3D SETUP
# ============================================================================

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "Must be a valid AWS region (e.g., us-east-1, eu-west-1)"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "k3d-microservices"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"

  validation {
    condition     = contains(["t3.large", "t3.xlarge", "t3.2xlarge", "m5.large", "m5.xlarge", "m5.2xlarge"], var.instance_type)
    error_message = "Must be a valid EC2 instance type suitable for k3d (t3.large or larger recommended)"
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.root_volume_size >= 30
    error_message = "Root volume size must be at least 30GB"
  }
}

variable "key_pair_name" {
  description = "AWS EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production"
  }
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default = {
    CreatedBy = "Terraform"
    Purpose   = "K3d-Microservices"
  }
}

