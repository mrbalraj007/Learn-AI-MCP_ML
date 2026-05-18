output "instances" {
  value = {
    for k, vm in module.ec2_instance : k => {
      public_ip  = vm.public_ip
      private_ip = vm.private_ip
      os_type    = vm.os_type
      name       = vm.name
    }
  }
  description = "All EC2 instances by logical key"
}

output "inventory_file_path" {
  value       = var.generate_ansible_inventory ? local_file.ansible_inventory[0].filename : null
  description = "Path to the generated Ansible inventory file"
}