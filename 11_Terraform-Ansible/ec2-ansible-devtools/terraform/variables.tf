###############################################################################
# Variables
###############################################################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2" # Sydney — adjust to your region
}

variable "project_name" {
  description = "Project name — used as prefix for all resource names"
  type        = string
  default     = "devtools-lab"
}

variable "environment" {
  description = "Environment name (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium" # 2 vCPU / 4 GB RAM — good for kind/docker
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "allowed_ssh_cidr" {
  description = "CIDR block(s) allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # ⚠️  Restrict to your IP in production: ["x.x.x.x/32"]
}

variable "vpc_id" {
  description = "VPC ID to launch the instance in (leave blank to use default VPC)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in (leave blank for auto-select)"
  type        = string
  default     = ""
}
