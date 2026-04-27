# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Add provider mirror configuration to help with download issues
  provider_meta "aws" {
    module_name = "aws-terraform-provider"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" #change region as per you requirement
  
  # Add HTTP client configuration for better reliability
  http_proxy = null # Set your proxy if needed
  retries {
    max_attempts = 10
    mode         = "standard"
  }
}

terraform {
  backend "s3" {
    bucket         = "cf-templates-shlcjth566j2-us-east-1"
    key            = "environment/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    
    # Remove the unsupported retry parameters
  }
}
