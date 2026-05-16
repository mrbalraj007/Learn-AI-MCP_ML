###############################################################################
# Outputs
###############################################################################

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.ansible_target.id
}

output "instance_public_ip" {
  description = "EC2 Instance Public IP — used by Ansible dynamic inventory"
  value       = aws_instance.ansible_target.public_ip
}

output "instance_public_dns" {
  description = "EC2 Instance Public DNS"
  value       = aws_instance.ansible_target.public_dns
}

output "instance_ami" {
  description = "AMI used for the instance"
  value       = data.aws_ami.ubuntu_2204.id
}

output "key_pair_name" {
  description = "Name of the AWS Key Pair"
  value       = aws_key_pair.ec2_key.key_name
}

output "private_key_path" {
  description = "Local path to the SSH private key"
  value       = local_file.private_key.filename
  sensitive   = true
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ec2_sg.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ansible/${var.project_name}-key.pem ubuntu@${aws_instance.ansible_target.public_ip}"
}
