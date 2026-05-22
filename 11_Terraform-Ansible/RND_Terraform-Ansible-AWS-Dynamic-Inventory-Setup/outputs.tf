# Root Terraform Configuration - Outputs
# File: terraform/outputs.tf

output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "ec2_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = module.ec2.instance_public_ips
}

output "ec2_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = module.ec2.instance_private_ips
}

output "security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = module.ec2.security_group_id
}

output "ansible_inventory_json" {
  description = "Ansible inventory in JSON format"
  value       = module.ec2.ansible_inventory
}

output "inventory_summary" {
  description = "Summary of created instances"
  value       = module.ec2.inventory_summary
}

output "ssh_key_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.terraform_ec2_key.key_name
}

output "ami_id_used" {
  description = "AMI ID used for instances"
  value       = data.aws_ami.ubuntu.id
}

output "next_steps" {
  description = "Next steps for Ansible configuration"
  value = "1. Copy /terraform/inventory/hosts.json to Ansible server\n2. Run Ansible playbooks: ansible-playbook -i inventory/hosts.json playbooks/install_packages.yml\n3. Verify installation: ansible all -i inventory/hosts.json -m shell -a 'docker --version'"
}
