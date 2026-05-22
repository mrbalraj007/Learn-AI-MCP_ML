variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "key_name" {}

# variable "public_key_path" {}

variable "environment" {
  default = "dev"
}
