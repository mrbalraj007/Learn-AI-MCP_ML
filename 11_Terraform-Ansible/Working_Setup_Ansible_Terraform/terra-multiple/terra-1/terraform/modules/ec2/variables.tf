variable "instance_type" {}
variable "key_name" {}
variable "environment" {}

variable "os_type" {
  description = "Operating system: 'ubuntu' or 'windows'"
  validation {
    condition     = contains(["ubuntu", "windows"], var.os_type)
    error_message = "os_type must be 'ubuntu' or 'windows'"
  }
}

variable "name" {
  description = "Name tag for the EC2 instance"
}

variable "ami_id" {
  description = "Override AMI ID (optional; auto-resolved from os_type if not set)"
  type        = string
  default     = null
}

variable "user_data_override" {
  description = "Override user_data script (optional; uses OS default if not set)"
  type        = string
  default     = null
}

variable "winrm_script" {
  description = "Content of the WinRM configuration PowerShell script for Windows VMs"
  type        = string
  default     = ""
}