#!/bin/bash
# ============================================
# Terraform Setup Script for Terra-1 VM
# File: setup_terraform.sh
# 
# Purpose: Initialize Terraform environment on Terra-1
# Usage: bash setup_terraform.sh
# ============================================

set -e

echo "=========================================="
echo "Terraform Environment Setup - Terra-1"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check prerequisites
echo ""
echo "Checking prerequisites..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    echo "Install Terraform from: https://www.terraform.io/downloads.html"
    exit 1
fi
print_status "Terraform installed: $(terraform version | head -n1)"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    echo "Install AWS CLI with: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip && sudo ./aws/install"
    exit 1
fi
print_status "AWS CLI installed: $(aws --version)"

# Check if SSH key pair exists
SSH_KEY_PATH="$HOME/.ssh/terraform_ec2_key"
if [ ! -f "$SSH_KEY_PATH" ]; then
    print_warning "SSH key pair not found at $SSH_KEY_PATH"
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_KEY_PATH.pub"
    print_status "SSH key pair generated"
else
    print_status "SSH key pair exists at $SSH_KEY_PATH"
fi

# Setup Terraform directory structure
echo ""
echo "Setting up Terraform directory structure..."

TERRAFORM_DIR="${1:-.}"
mkdir -p "$TERRAFORM_DIR"/{modules/ec2,inventory,terraform.tfstate}

print_status "Terraform directories created"

# Initialize Terraform
echo ""
echo "Initializing Terraform..."

cd "$TERRAFORM_DIR"

# Check if main.tf exists
if [ ! -f main.tf ]; then
    print_error "main.tf not found in $TERRAFORM_DIR"
    echo "Please ensure all Terraform files are in place"
    exit 1
fi

# Initialize Terraform
terraform init
print_status "Terraform initialized"

# Validate configuration
echo ""
echo "Validating Terraform configuration..."
if terraform validate; then
    print_status "Terraform configuration is valid"
else
    print_error "Terraform configuration is invalid"
    exit 1
fi

# Check AWS credentials
echo ""
echo "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ACCOUNT_USER=$(aws sts get-caller-identity --query Arn --output text)
    print_status "AWS credentials configured"
    echo "  Account ID: $ACCOUNT_ID"
    echo "  User: $ACCOUNT_USER"
else
    print_error "AWS credentials not configured"
    echo "Configure with: aws configure"
    exit 1
fi

# Create terraform.tfvars template if not exists
echo ""
echo "Checking terraform.tfvars..."

if [ ! -f terraform.tfvars ]; then
    print_warning "terraform.tfvars not found"
    echo "Creating terraform.tfvars template..."
    
    # Get public key
    PUBLIC_KEY=$(cat "$SSH_KEY_PATH.pub")
    
    cat > terraform.tfvars << EOF
aws_region    = "us-east-1"
environment   = "dev"
project_name  = "k8s-cluster"
instance_type = "t3.medium"
instance_count = 2

public_key_content = "$PUBLIC_KEY"

assign_public_ip      = true
assign_elastic_ip     = false
allowed_ssh_cidr      = ["0.0.0.0/0"]
root_volume_size      = 30
root_volume_type      = "gp3"
root_volume_encrypted = true

additional_tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Backup      = "true"
}
EOF
    print_status "terraform.tfvars created"
else
    print_status "terraform.tfvars exists"
fi

# Display summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review and update terraform.tfvars if needed:"
echo "   - Update aws_region, environment, project_name"
echo "   - Adjust instance_count and instance_type"
echo ""
echo "2. Run Terraform plan to review resources:"
echo "   terraform plan -out=tfplan"
echo ""
echo "3. Apply configuration to create EC2 instances:"
echo "   terraform apply tfplan"
echo ""
echo "4. After EC2 instances are created:"
echo "   - Copy inventory/inventory.json to Ans-1 server"
echo "   - Copy ~/.ssh/terraform_ec2_key to Ans-1 server"
echo ""
echo "5. On Ans-1 server, run Ansible playbook:"
echo "   ansible-playbook -i inventory/hosts.json playbooks/install_packages.yml"
echo ""
echo "=========================================="
