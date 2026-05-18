# ── Key pair ──

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${path.module}/devtools-key.pem"
  file_permission = "0400"
}

resource "local_file" "public_key" {
  content  = tls_private_key.generated.public_key_openssh
  filename = "${path.module}/devtools-key.pub"
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.generated.public_key_openssh
}

# ── EC2 instances ──

module "ec2_instance" {
  source   = "./modules/ec2"
  for_each = var.vm_configs

  instance_type      = each.value.instance_type
  key_name           = aws_key_pair.deployer.key_name
  environment        = var.environment
  os_type            = each.value.os_type
  name               = each.value.name
  ami_id             = lookup(each.value, "ami_id", null)
  user_data_override = lookup(each.value, "user_data", null)
  winrm_script       = file("${path.module}/script/configure-winrm.ps1")
}

# ── Ansible inventory generation ──

locals {
  vm_inventory = {
    for k, vm in module.ec2_instance : k => {
      public_ip  = vm.public_ip
      private_ip = vm.private_ip
      os_type    = vm.os_type
      name       = vm.name
    }
  }

  ansible_inventory_ini = templatefile(
    "${path.module}/templates/inventory.ini.tftpl",
    { vms = local.vm_inventory }
  )
}

resource "local_file" "ansible_inventory" {
  count = var.generate_ansible_inventory ? 1 : 0

  content  = local.ansible_inventory_ini
  filename = "${path.module}/ansible_inventory.ini"
}

# ── Remote Ansible trigger (optional) ──

resource "null_resource" "ansible_trigger" {
  count = var.ansible_config != null ? 1 : 0

  triggers = {
    inventory_md5 = md5(local.ansible_inventory_ini)
  }

  depends_on = [module.ec2_instance, local_file.ansible_inventory]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ansible_config.user
      private_key = file(var.ansible_config.ssh_key_path)
      host        = var.ansible_config.host
    }

    inline = [
      "mkdir -p ${var.ansible_config.project_dir}/inventory",
    ]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.ansible_config.user
      private_key = file(var.ansible_config.ssh_key_path)
      host        = var.ansible_config.host
    }

    source      = local_file.ansible_inventory[0].filename
    destination = "${var.ansible_config.project_dir}/inventory/hosts.ini"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.ansible_config.user
      private_key = file(var.ansible_config.ssh_key_path)
      host        = var.ansible_config.host
    }

    source      = local_file.private_key.filename
    destination = "${var.ansible_config.project_dir}/ssh_key.pem"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ansible_config.user
      private_key = file(var.ansible_config.ssh_key_path)
      host        = var.ansible_config.host
    }

    inline = [
      "chmod 600 ${var.ansible_config.project_dir}/ssh_key.pem",
      var.ansible_config.venv_path != "" ? "source ${var.ansible_config.venv_path}/bin/activate && cd ${var.ansible_config.project_dir} && ansible-playbook -i inventory/hosts.ini ${var.ansible_config.playbook}" : "cd ${var.ansible_config.project_dir} && ansible-playbook -i inventory/hosts.ini ${var.ansible_config.playbook}",
    ]
  }
}