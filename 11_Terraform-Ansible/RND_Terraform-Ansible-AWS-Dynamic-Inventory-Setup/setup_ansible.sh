#!/bin/bash
# ============================================
# Ansible Setup Script for Ans-1 VM
# File: setup_ansible.sh
#
# Purpose: Initialize Ansible environment on Ans-1
# Usage: bash setup_ansible.sh
# ============================================

set -e

echo "=========================================="
echo "Ansible Environment Setup - Ans-1"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check prerequisites
echo ""
echo "Checking prerequisites..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed"
    echo "Install with: sudo apt-get update && sudo apt-get install -y python3 python3-pip"
    exit 1
fi
print_status "Python 3 installed: $(python3 --version)"

# Setup Ansible directory structure
echo ""
echo "Setting up Ansible directory structure..."

ANSIBLE_DIR="${1:-.}"
mkdir -p "$ANSIBLE_DIR"/{inventory,playbooks,roles,logs,group_vars,host_vars}

print_status "Ansible directories created"

# Install Ansible and dependencies
echo ""
echo "Installing Ansible and dependencies..."

if [ -f "$ANSIBLE_DIR/requirements.txt" ]; then
    pip3 install -r "$ANSIBLE_DIR/requirements.txt"
    print_status "Ansible installed from requirements.txt"
else
    print_warning "requirements.txt not found, installing Ansible directly"
    pip3 install ansible ansible-lint
    print_status "Ansible installed"
fi

# Verify Ansible installation
if ! command -v ansible &> /dev/null; then
    print_error "Ansible installation failed"
    exit 1
fi
print_status "Ansible installed: $(ansible --version | head -n1)"

# Setup SSH
echo ""
echo "Setting up SSH configuration..."

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Check if SSH key exists
if [ -f "$SSH_DIR/terraform_ec2_key.pem" ]; then
    print_status "SSH key found at $SSH_DIR/terraform_ec2_key.pem"
else
    print_warning "SSH key not found at $SSH_DIR/terraform_ec2_key.pem"
    echo "You need to copy the private key from Terra-1:"
    echo "  On Terra-1: scp ~/.ssh/terraform_ec2_key user@ans-1:~/.ssh/terraform_ec2_key.pem"
    echo "Then run: chmod 600 ~/.ssh/terraform_ec2_key.pem"
fi

# Create SSH config for EC2 instances
echo ""
echo "Creating SSH configuration for EC2 instances..."

SSH_CONFIG="$SSH_DIR/config"

if [ ! -f "$SSH_CONFIG" ]; then
    cat > "$SSH_CONFIG" << 'EOF'
# EC2 Instances Configuration
Host ec2-instances
    IdentityFile ~/.ssh/terraform_ec2_key.pem
    User ubuntu
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    PasswordAuthentication no
EOF
    chmod 600 "$SSH_CONFIG"
    print_status "SSH config created"
else
    print_status "SSH config exists"
fi

# Create ansible.cfg if not exists
echo ""
echo "Creating Ansible configuration..."

cd "$ANSIBLE_DIR"

if [ ! -f ansible.cfg ]; then
    print_warning "ansible.cfg not found, creating default configuration"
    cat > ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory/hosts.json
host_key_checking = False
deprecation_warnings = False
remote_user = ubuntu
private_key_file = ~/.ssh/terraform_ec2_key.pem
timeout = 30
gather_timeout = 10
connection = ssh
show_skipped_hosts = True
log_path = ./logs/ansible.log
forks = 5
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
force_color = True
callback_whitelist = profile_tasks, timer

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOF
    print_status "ansible.cfg created"
else
    print_status "ansible.cfg exists"
fi

# Check for inventory file
echo ""
echo "Checking inventory file..."

if [ ! -f "$ANSIBLE_DIR/inventory/hosts.json" ] && [ ! -f "$ANSIBLE_DIR/inventory/inventory.json" ]; then
    print_warning "Inventory file not found"
    echo "You need to copy the inventory from Terra-1:"
    echo "  On Terra-1: terraform apply"
    echo "  Then: scp -r inventory/inventory.json user@ans-1:~/ansible/inventory/"
    
    # Create template inventory
    cat > "$ANSIBLE_DIR/inventory/hosts.json" << 'EOF'
{
  "all": {
    "hosts": {
      "example-host": {
        "ansible_host": "10.0.0.1",
        "ansible_user": "ubuntu",
        "instance_id": "i-0123456789abcdef0"
      }
    },
    "vars": {
      "ansible_ssh_private_key_file": "~/.ssh/terraform_ec2_key.pem",
      "ansible_ssh_common_args": "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    }
  }
}
EOF
    print_warning "Template inventory created at $ANSIBLE_DIR/inventory/hosts.json"
else
    print_status "Inventory file exists"
fi

# Make dynamic inventory script executable
if [ -f "$ANSIBLE_DIR/inventory/dynamic_inventory.py" ]; then
    chmod +x "$ANSIBLE_DIR/inventory/dynamic_inventory.py"
    print_status "Dynamic inventory script is executable"
fi

# Create playbook directory structure
echo ""
echo "Creating playbook structure..."

if [ ! -f "$ANSIBLE_DIR/playbooks/install_packages.yml" ]; then
    print_warning "Playbook not found at $ANSIBLE_DIR/playbooks/install_packages.yml"
    echo "You need to copy the playbooks from the setup"
fi

# Display summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Directory structure:"
echo "  $ANSIBLE_DIR/"
echo "  ├── inventory/"
echo "  │   ├── hosts.json"
echo "  │   └── dynamic_inventory.py"
echo "  ├── playbooks/"
echo "  │   └── install_packages.yml"
echo "  ├── roles/"
echo "  ├── logs/"
echo "  ├── ansible.cfg"
echo "  └── requirements.txt"
echo ""
echo "Pre-execution checklist:"
echo "[ ] Copy terraform_ec2_key.pem from Terra-1 to ~/.ssh/"
echo "[ ] Copy inventory.json from Terra-1 to inventory/"
echo "[ ] Verify SSH key permissions: chmod 600 ~/.ssh/terraform_ec2_key.pem"
echo "[ ] Test connectivity: ansible all -i inventory/hosts.json -m ping"
echo ""
echo "To run the playbook:"
echo "  ansible-playbook -i inventory/hosts.json playbooks/install_packages.yml"
echo ""
echo "To run with verbose output:"
echo "  ansible-playbook -i inventory/hosts.json playbooks/install_packages.yml -vvv"
echo ""
echo "To run specific tags:"
echo "  ansible-playbook -i inventory/hosts.json playbooks/install_packages.yml --tags docker"
echo ""
echo "=========================================="
