variable "aws_region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "devtools-key"
}

variable "environment" {
  default = "dev"
}

variable "vm_configs" {
  description = "Map of VM configurations. Key is a stable VM identifier."
  type = map(object({
    os_type       = string
    instance_type = optional(string, "t3.medium")
    name          = string
    ami_id        = optional(string)
    user_data     = optional(string)
  }))
  default = {}
}

variable "ansible_config" {
  description = "Remote Ansible controller configuration"
  type = object({
    host         = string
    user         = string
    ssh_key_path = string
    project_dir  = string
    venv_path    = optional(string, "")
    playbook     = string
  })
  default = null
}

variable "generate_ansible_inventory" {
  description = "Generate an Ansible inventory file locally"
  type        = bool
  default     = true
}