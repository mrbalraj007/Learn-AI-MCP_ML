###############################################################################
# Terraform Main Configuration
# Creates: Key Pair, Security Group, EC2 Instance (Ubuntu 22.04)
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################################################
# Data Sources
###############################################################################

# Latest Ubuntu 22.04 LTS AMI (Canonical official)
data "aws_ami" "ubuntu_2204" {
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

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Fetch caller identity for tagging
data "aws_caller_identity" "current" {}

###############################################################################
# SSH Key Pair
###############################################################################

# Generate RSA private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register public key in AWS
resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = local.common_tags
}

# Save private key to local disk for Ansible
resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/../ansible/${var.project_name}-key.pem"
  file_permission = "0600"
}

###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name} EC2 instance"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-sg" })
}

# Use default VPC if no VPC ID provided
data "aws_vpc" "default" {
  default = true
}

###############################################################################
# EC2 Instance
###############################################################################

resource "aws_instance" "ansible_target" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = var.subnet_id != "" ? var.subnet_id : null

  # Enable detailed monitoring
  monitoring = true

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, { Name = "${var.project_name}-root-vol" })
  }

  # User data — ensures python3 present for Ansible
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip
  EOF

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-instance"
    AnsibleRole = "devtools"
  })

  # Wait for instance to be fully initialised before Terraform marks it done
  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Outputs written to a file Ansible can consume (fallback / reference)
###############################################################################

resource "local_file" "ansible_inventory_static" {
  content  = <<-EOT
    # Static inventory (fallback — dynamic inventory is preferred)
    [devtools]
    ${aws_instance.ansible_target.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./${var.project_name}-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
  filename = "${path.module}/../ansible/inventory/static_hosts.ini"
}

###############################################################################
# Locals
###############################################################################

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = data.aws_caller_identity.current.account_id
  }
}
