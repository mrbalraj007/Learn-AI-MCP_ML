# Terraform Variables Values
# File: terraform/terraform.tfvars
# IMPORTANT: This file contains your SSH public key - keep it secure!

aws_region    = "us-east-1"
environment   = "dev"
project_name  = "k8s-cluster"
instance_type = "t3.medium"
instance_count = 2

# SSH Public Key - REPLACE with your actual public key content
# Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform_ec2_key -N ""
# Then cat ~/.ssh/terraform_ec2_key.pub and paste content below
public_key_content = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... YOUR_PUBLIC_KEY_HERE"

assign_public_ip      = true
assign_elastic_ip     = false
allowed_ssh_cidr      = ["0.0.0.0/0"]
root_volume_size      = 30
root_volume_type      = "gp3"
root_volume_encrypted = true

additional_tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Backup      = "true"
}
