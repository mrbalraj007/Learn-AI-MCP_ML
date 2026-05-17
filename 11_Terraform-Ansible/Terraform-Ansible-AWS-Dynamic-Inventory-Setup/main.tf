# Root Terraform Configuration
# File: terraform/main.tf (in Terra-1 VM)

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration (optional but recommended)
  # Uncomment and configure if using remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ec2-infrastructure/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment  = var.environment
      Project      = var.project_name
      CreatedBy    = "Terraform"
      CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
      ManagedBy    = "Terraform"
    }
  }
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source for latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate SSH key pair for EC2 access
resource "aws_key_pair" "terraform_ec2_key" {
  key_name   = "${var.environment}-${var.project_name}-key"
  public_key = var.public_key_content

  tags = {
    Name = "${var.environment}-${var.project_name}-keypair"
  }
}

# Call EC2 Module
module "ec2" {
  source = "./modules/ec2"

  environment          = var.environment
  project_name         = var.project_name
  vpc_id               = data.aws_vpc.default.id
  subnet_id            = data.aws_subnets.default.ids[0]
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  instance_count       = var.instance_count
  assign_public_ip     = var.assign_public_ip
  assign_elastic_ip    = var.assign_elastic_ip
  allowed_ssh_cidr     = var.allowed_ssh_cidr
  root_volume_size     = var.root_volume_size
  root_volume_type     = var.root_volume_type
  root_volume_encrypted = var.root_volume_encrypted

  tags = var.additional_tags
}

# Local file to store Ansible inventory
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory/hosts.json"
  content = jsonencode({
    all = {
      hosts = {
        for i, instance in module.ec2.inventory_summary : instance.instance_name => {
          ansible_host = instance.public_ip != "N/A" ? instance.public_ip : instance.private_ip
          ansible_user = "ubuntu"
          instance_id  = instance.instance_id
          environment  = var.environment
          project      = var.project_name
        }
      }
      vars = {
        ansible_ssh_private_key_file = "~/.ssh/terraform_ec2_key.pem"
        ansible_ssh_common_args      = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
      }
    }
  })

  depends_on = [module.ec2]
}

# Output inventory as JSON for parsing
resource "local_file" "inventory_json" {
  filename = "${path.module}/inventory/inventory.json"
  content = jsonencode({
    instances = module.ec2.inventory_summary
    timestamp = timestamp()
  })

  depends_on = [module.ec2]
}
