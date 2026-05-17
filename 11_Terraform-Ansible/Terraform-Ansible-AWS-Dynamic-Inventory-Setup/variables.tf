# Root Terraform Configuration - Variables
# File: terraform/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "k8s-cluster"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 2
}

variable "assign_public_ip" {
  description = "Assign public IP to instances"
  type        = bool
  default     = true
}

variable "assign_elastic_ip" {
  description = "Assign Elastic IP to instances"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP range for production
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}

variable "public_key_content" {
  description = "Public SSH key content for EC2 key pair"
  type        = string
  sensitive   = true
}

variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
