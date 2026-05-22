terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket       = "demo-terra22062025"
    key          = "devtools/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

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

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}