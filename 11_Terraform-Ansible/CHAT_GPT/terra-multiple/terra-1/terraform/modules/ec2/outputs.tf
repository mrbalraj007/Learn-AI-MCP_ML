output "public_ip" {
  value = aws_instance.this.public_ip
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "os_type" {
  value = var.os_type
}

output "name" {
  value = var.name
}

output "instance_id" {
  value = aws_instance.this.id
}

output "ansible_role" {
  value = var.os_type == "ubuntu" ? "linux-devtools" : "windows-devtools"
}