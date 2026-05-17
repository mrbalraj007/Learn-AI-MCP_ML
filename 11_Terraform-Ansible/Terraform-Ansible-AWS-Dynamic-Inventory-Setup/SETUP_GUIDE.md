# Complete Setup Guide: Terraform EC2 + Ansible Configuration
## Enterprise-Grade Infrastructure Automation

---

## Table of Contents
1. Architecture Overview
2. Prerequisites & Requirements
3. Pre-Execution Checklist
4. Step-by-Step Setup Guide
5. Terraform Configuration (Terra-1)
6. Ansible Configuration (Ans-1)
7. Execution Workflow
8. Troubleshooting Guide
9. Security Best Practices

---

## 1. Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cloud (us-east-1)                  │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  VPC (Default)                                       │   │
│  │                                                       │   │
│  │  ┌─────────────────────────────────────────────┐     │   │
│  │  │  Public Subnet                              │     │   │
│  │  │                                              │     │   │
│  │  │  ┌──────────────────┐  ┌──────────────────┐ │     │   │
│  │  │  │  EC2 Instance-1  │  │  EC2 Instance-2  │ │     │   │
│  │  │  │  (Ubuntu 22.04)  │  │  (Ubuntu 22.04)  │ │     │   │
│  │  │  │  - Docker        │  │  - Docker        │ │     │   │
│  │  │  │  - kubectl       │  │  - kubectl       │ │     │   │
│  │  │  │  - kind          │  │  - kind          │ │     │   │
│  │  │  │  - curl, tmux    │  │  - curl, tmux    │ │     │   │
│  │  │  └──────────────────┘  └──────────────────┘ │     │   │
│  │  │                                              │     │   │
│  │  └─────────────────────────────────────────────┘     │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                     On-Premises (VMware)                     │
│                                                               │
│  ┌──────────────────────┐      ┌──────────────────────┐    │
│  │  Terra-1 VM          │      │  Ans-1 VM            │    │
│  │  (Ubuntu 22.04)      │      │  (Ubuntu 22.04)      │    │
│  │                      │      │                      │    │
│  │  Terraform           │      │  Ansible             │    │
│  │  - AWS CLI           │      │  - Python3           │    │
│  │  - SSH Key Pair      │      │  - SSH Client        │    │
│  │  - Modules           │      │  - Dynamic Inventory │    │
│  │  - State Files       │      │  - Playbooks         │    │
│  │  - Inventory Files   ├──────┤  - Roles             │    │
│  │                      │  SCP  │                      │    │
│  │ Generates:           │      │ Executes:            │    │
│  │ - EC2 Instances      │      │ - Package Install    │    │
│  │ - Security Groups    │      │ - Configuration Mgmt │    │
│  │ - inventory.json     │      │ - Service Management │    │
│  └──────────────────────┘      └──────────────────────┘    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. Terraform Phase (Terra-1)
   ├─ SSH Key Generation
   ├─ AWS Credentials Verification
   ├─ Terraform Initialization
   ├─ Infrastructure Planning (terraform plan)
   ├─ Infrastructure Creation (terraform apply)
   │  └─ EC2 Instances Created ✓
   │  └─ Security Groups Created ✓
   └─ Inventory Generation (inventory.json)
      └─ JSON file with EC2 IPs

2. Transfer Phase
   ├─ Copy inventory.json → Ans-1
   ├─ Copy SSH private key → Ans-1
   └─ Update Ansible configuration

3. Ansible Phase (Ans-1)
   ├─ Inventory Parsing
   ├─ SSH Connectivity Test (ping)
   ├─ Playbook Execution
   │  ├─ System dependency installation
   │  ├─ Docker installation & configuration
   │  ├─ kubectl installation
   │  ├─ kind installation
   │  ├─ Additional tools (curl, tmux, unzip)
   │  └─ Service verification
   └─ Installation Complete ✓
```

---

## 2. Prerequisites & Requirements

### Software Requirements

#### Terra-1 VM (Terraform Server)
```
Operating System: Ubuntu 22.04 LTS
RAM: Minimum 2GB (4GB recommended)
Disk Space: Minimum 10GB
Network: Internet access to AWS

Required Software:
- Terraform v1.0+ 
- AWS CLI v2
- OpenSSH Server
- Git
- curl
- jq (optional, for JSON parsing)
```

#### Ans-1 VM (Ansible Server)
```
Operating System: Ubuntu 22.04 LTS
RAM: Minimum 2GB (4GB recommended)
Disk Space: Minimum 5GB
Network: Connectivity to EC2 instances (SSH port 22)

Required Software:
- Python 3.8+
- Ansible 2.12+
- OpenSSH Client
- curl
- jq (optional)
```

### AWS Requirements
```
AWS Account with:
- EC2 service access
- IAM permissions to:
  * create/describe EC2 instances
  * create/manage security groups
  * create/manage key pairs
  * create/manage VPCs (if not using default)
- Default VPC (or custom VPC specified)
- At least 2 available IPs in target subnet
```

### Network Requirements
```
Connectivity:
- Terra-1 → AWS API (HTTPS port 443)
- Ans-1 → EC2 Instances (SSH port 22)
- Terra-1 → Ans-1 (SCP for file transfer)
- EC2 Instances → Internet (for package downloads)

Firewall Rules:
- Allow SSH inbound on EC2 instances
- Allow outbound package manager traffic (apt)
- Allow outbound HTTPS (for Docker, kubectl downloads)
```

---

## 3. Pre-Execution Checklist

### On Local Machine (Before Setup)

- [ ] VMware Workstation Pro 17 installed and running
- [ ] Terra-1 VM created with Ubuntu 22.04 LTS
- [ ] Ans-1 VM created with Ubuntu 22.04 LTS
- [ ] Network connectivity between both VMs
- [ ] Network connectivity from both VMs to Internet
- [ ] AWS Account credentials available
- [ ] Terraform files downloaded/prepared

### Verification Commands

```bash
# Check Ubuntu version
cat /etc/os-release

# Check network connectivity
ping -c 3 8.8.8.8

# Check Inter-VM connectivity
# From Terra-1:
ping <Ans-1-IP>

# From Ans-1:
ping <Terra-1-IP>
```

---

## 4. Step-by-Step Setup Guide

### PHASE 1: TERRAFORM SETUP (Terra-1 VM)

#### Step 1.1: Install Terraform

```bash
# Update package lists
sudo apt-get update
sudo apt-get upgrade -y

# Download and install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Verify installation
terraform version
# Expected output: Terraform v1.6.0 on linux_amd64
```

#### Step 1.2: Install AWS CLI

```bash
# Download AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip

# Install
sudo ./aws/install

# Verify installation
aws --version
# Expected output: aws-cli/2.x.x ...

# Cleanup
rm -rf aws awscliv2.zip
```

#### Step 1.3: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# You will be prompted for:
# AWS Access Key ID: [Enter your access key]
# AWS Secret Access Key: [Enter your secret key]
# Default region name: us-east-1
# Default output format: json

# Verify AWS credentials
aws sts get-caller-identity
# Output should show your AWS account information
```

#### Step 1.4: Setup SSH Key Pair

```bash
# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform_ec2_key -N ""

# Verify key generation
ls -la ~/.ssh/terraform_ec2_key*
# Should show:
# -rw------- terraform_ec2_key (private)
# -rw-r--r-- terraform_ec2_key.pub (public)

# Get public key content (you'll need this for terraform.tfvars)
cat ~/.ssh/terraform_ec2_key.pub
```

#### Step 1.5: Prepare Terraform Files

```bash
# Create project directory
mkdir -p ~/terraform/modules/ec2
cd ~/terraform

# File structure should be:
# terraform/
# ├── main.tf                    (root configuration)
# ├── variables.tf               (variable definitions)
# ├── outputs.tf                 (output definitions)
# ├── terraform.tfvars           (variable values - UPDATE THIS)
# ├── modules/
# │   └── ec2/
# │       ├── main.tf            (EC2 module)
# │       ├── variables.tf        (module variables)
# │       └── outputs.tf          (module outputs)
# └── inventory/                 (generated after apply)
#     └── inventory.json         (copy to Ans-1)

# Copy all files to ~/terraform directory
# (Files provided in the solution)
```

#### Step 1.6: Update terraform.tfvars

```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Update the following values:
# 1. public_key_content: Replace with your public key
#    Command to get: cat ~/.ssh/terraform_ec2_key.pub

# Example terraform.tfvars:
# aws_region = "us-east-1"
# environment = "dev"
# project_name = "k8s-cluster"
# instance_type = "t3.medium"
# instance_count = 2
# public_key_content = "ssh-rsa AAAAB3... (full key)"
# assign_public_ip = true
# ...

# Save file (Ctrl+O, Enter, Ctrl+X)
```

#### Step 1.7: Initialize and Validate Terraform

```bash
# Change to terraform directory
cd ~/terraform

# Initialize Terraform
terraform init
# Output should show:
# - Provider plugins downloaded
# - Backend initialized
# - Ready to apply configuration

# Validate configuration
terraform validate
# Output should show: Success! The configuration is valid.

# Format code (optional)
terraform fmt -recursive
```

#### Step 1.8: Plan and Review Infrastructure

```bash
# Create execution plan (review before applying)
terraform plan -out=tfplan

# Output shows:
# - 1 aws_security_group will be created
# - 2 aws_instance will be created
# - 1 aws_key_pair will be created
# - 2 local_file (inventory) will be created

# REVIEW THE PLAN CAREFULLY BEFORE PROCEEDING
```

#### Step 1.9: Apply Terraform Configuration

```bash
# Apply configuration to create resources
terraform apply tfplan

# Wait for completion (typically 5-10 minutes)
# Output will show:
# - Creating EC2 instances...
# - Creating security groups...
# - Writing inventory files...

# Verify resources created
aws ec2 describe-instances --query 'Reservations[0].Instances[*].[InstanceId,PublicIpAddress,State.Name]' --output table

# Check inventory file created
ls -la inventory/
cat inventory/inventory.json
```

#### Step 1.10: Export Outputs

```bash
# Get output values
terraform output

# Store for reference
terraform output -json > terraform_output.json

# Get public IPs for Ansible connectivity
terraform output -raw 'ec2_public_ips'
# Output: ["203.0.113.1", "203.0.113.2"]
```

### PHASE 2: FILE TRANSFER (Terra-1 to Ans-1)

#### Step 2.1: Prepare Files on Terra-1

```bash
# On Terra-1, create transfer bundle
cd ~/terraform

# Copy inventory file
cp inventory/inventory.json ~/transfer/

# Copy SSH private key (SECURE TRANSFER ONLY)
cp ~/.ssh/terraform_ec2_key ~/transfer/

# Set proper permissions
chmod 600 ~/transfer/terraform_ec2_key
chmod 644 ~/transfer/inventory.json

# Verify files
ls -la ~/transfer/
```

#### Step 2.2: Transfer Files to Ans-1

```bash
# On Terra-1, transfer files to Ans-1
# Replace <ANS1_IP> with actual IP of Ans-1 VM
# Replace <USERNAME> with your username on Ans-1

# Create directory on Ans-1
ssh <USERNAME>@<ANS1_IP> "mkdir -p ~/ansible/inventory"

# Transfer inventory file
scp ~/transfer/inventory.json <USERNAME>@<ANS1_IP>:~/ansible/inventory/

# Transfer SSH private key
scp ~/transfer/terraform_ec2_key <USERNAME>@<ANS1_IP>:~/.ssh/

# On Ans-1, set proper permissions
ssh <USERNAME>@<ANS1_IP> "chmod 600 ~/.ssh/terraform_ec2_key"

# Verify transfer
ssh <USERNAME>@<ANS1_IP> "ls -la ~/.ssh/terraform_ec2_key ~/ansible/inventory/inventory.json"
```

### PHASE 3: ANSIBLE SETUP (Ans-1 VM)

#### Step 3.1: Install Python and pip

```bash
# Update package lists
sudo apt-get update
sudo apt-get upgrade -y

# Install Python 3 and pip
sudo apt-get install -y python3 python3-pip python3-venv

# Verify installation
python3 --version
pip3 --version
```

#### Step 3.2: Install Ansible

```bash
# Create virtual environment (optional but recommended)
python3 -m venv ~/ansible_env
source ~/ansible_env/bin/activate

# Install Ansible
pip3 install ansible>=2.12.0 ansible-lint

# Verify installation
ansible --version
# Output should show: ansible [core 2.x.x] ...

# Deactivate venv if not using
# deactivate
```

#### Step 3.3: Setup Ansible Directory Structure

```bash
# Create Ansible project directory
mkdir -p ~/ansible/{inventory,playbooks,roles,logs,group_vars,host_vars}
cd ~/ansible

# Directory structure:
# ansible/
# ├── inventory/
# │   ├── hosts.json                    (from Terraform)
# │   ├── inventory.json               (from Terraform)
# │   └── dynamic_inventory.py          (provided)
# ├── playbooks/
# │   └── install_packages.yml          (provided)
# ├── roles/                            (for future use)
# ├── logs/                             (Ansible output logs)
# ├── group_vars/                       (group variables)
# ├── host_vars/                        (host-specific variables)
# ├── ansible.cfg                       (provided)
# └── requirements.txt                  (provided)
```

#### Step 3.4: Copy Ansible Configuration Files

```bash
# Copy files to ~/ansible directory
# Files to copy:
# - ansible/ansible.cfg → ~/ansible/
# - ansible/requirements.txt → ~/ansible/
# - ansible/playbooks/install_packages.yml → ~/ansible/playbooks/
# - ansible/inventory/dynamic_inventory.py → ~/ansible/inventory/

# Verify files
ls -la ~/ansible/ansible.cfg
ls -la ~/ansible/playbooks/install_packages.yml
ls -la ~/ansible/inventory/

# Make scripts executable
chmod +x ~/ansible/inventory/dynamic_inventory.py
```

#### Step 3.5: Verify Inventory File

```bash
# Check inventory format
cat ~/ansible/inventory/inventory.json | python3 -m json.tool

# Expected output:
# {
#   "all": {
#     "hosts": {
#       "dev-k8s-cluster-1": {
#         "ansible_host": "203.0.113.1",
#         "ansible_user": "ubuntu",
#         "instance_id": "i-0123456789abcdef0"
#       },
#       "dev-k8s-cluster-2": {
#         "ansible_host": "203.0.113.2",
#         ...
#       }
#     },
#     ...
#   }
# }
```

#### Step 3.6: Test SSH Connectivity

```bash
# Test SSH connection to each EC2 instance
cd ~/ansible

# Test SSH manually first
ssh -i ~/.ssh/terraform_ec2_key ubuntu@<EC2_PUBLIC_IP>
# Should connect without prompting for password
# Type 'exit' to disconnect

# Test with Ansible ping module
ansible all -i inventory/inventory.json -m ping

# Expected output:
# dev-k8s-cluster-1 | SUCCESS => {
#     "ansible_facts": {...},
#     "changed": false,
#     "ping": "pong"
# }
# dev-k8s-cluster-2 | SUCCESS => {...}
```

### PHASE 4: ANSIBLE PLAYBOOK EXECUTION (Ans-1 VM)

#### Step 4.1: Pre-Execution Checks

```bash
# Verify playbook syntax
cd ~/ansible
ansible-playbook playbooks/install_packages.yml --syntax-check

# Should output: playbook: playbooks/install_packages.yml

# Get list of tasks that will run
ansible-playbook playbooks/install_packages.yml --list-tasks

# Dry-run (check mode - doesn't make changes)
ansible-playbook playbooks/install_packages.yml -i inventory/inventory.json --check
```

#### Step 4.2: Execute Playbook

```bash
# Run the playbook
cd ~/ansible
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml

# Standard execution with verbose output
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml -v

# Very verbose output (for debugging)
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml -vvv

# Expected output includes:
# PLAY [Install Required Packages on EC2 Instances]
# TASK [Install system dependencies]
# ...
# PLAY RECAP
# dev-k8s-cluster-1 : ok=X changed=Y failed=0
# dev-k8s-cluster-2 : ok=X changed=Y failed=0
```

#### Step 4.3: Verify Installation

```bash
# Run verification tasks only
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml --tags verify

# Manually verify on each instance
ansible all -i inventory/inventory.json -m shell -a "docker --version"
ansible all -i inventory/inventory.json -m shell -a "kubectl version --client --short"
ansible all -i inventory/inventory.json -m shell -a "kind version"
ansible all -i inventory/inventory.json -m shell -a "curl --version | head -1"
ansible all -i inventory/inventory.json -m shell -a "tmux -V"

# Connect to instance to verify
ssh -i ~/.ssh/terraform_ec2_key ubuntu@<EC2_PUBLIC_IP>

# On EC2 instance:
docker ps
docker version
kubectl version --client
kind version
which curl tmux unzip
```

#### Step 4.4: Post-Installation Tasks

```bash
# Check installation logs on instances
ansible all -i inventory/inventory.json -m shell -a "cat /var/log/package_installation.log"

# Verify Docker daemon is running
ansible all -i inventory/inventory.json -m shell -a "systemctl status docker"

# Check for any errors in Ansible logs
tail -f logs/ansible.log
```

---

## 5. Terraform Configuration Details

### Module Structure (Reusable Globally)

The EC2 module in `modules/ec2/` is designed to be reusable across projects:

```hcl
# To use in another project:
module "ec2_prod" {
  source = "./modules/ec2"
  
  environment     = "prod"
  project_name    = "my-app"
  vpc_id          = aws_vpc.prod.id
  subnet_id       = aws_subnet.prod.id
  ami_id          = data.aws_ami.ubuntu.id
  instance_count  = 5
  instance_type   = "t3.large"
  # ... other variables
}
```

### Key Features

1. **Flexible Sizing**: Control instance count and type via variables
2. **Security Groups**: Automatically configured with SSH, HTTP(S), and Kubernetes ports
3. **Dynamic Inventory**: Generates inventory.json automatically
4. **Tagging Strategy**: Consistent resource tagging for AWS cost allocation
5. **Encryption**: EBS volumes encrypted by default
6. **Monitoring**: Optional detailed CloudWatch monitoring
7. **Key Pair Management**: Managed through Terraform

### Output Management

The module outputs are specially formatted for Ansible consumption:

```json
{
  "all": {
    "hosts": {
      "dev-k8s-cluster-1": {
        "ansible_host": "203.0.113.1",
        "ansible_user": "ubuntu",
        "instance_id": "i-123...",
        "environment": "dev",
        "project": "k8s-cluster"
      }
    },
    "vars": {
      "ansible_ssh_private_key_file": "~/.ssh/terraform_ec2_key.pem",
      "ansible_ssh_common_args": "..."
    }
  }
}
```

---

## 6. Ansible Configuration Details

### Playbook Features

The `install_packages.yml` playbook includes:

#### Pre-Tasks
- Wait for EC2 to be fully ready
- Update package cache
- Display system information

#### Main Tasks
1. **System Dependencies** (curl, wget, git, build-essential, etc.)
2. **Docker Installation**
   - Add Docker repository
   - Install Docker CE with plugins
   - Configure daemon settings
   - Add user to docker group
   - Enable and start service

3. **kubectl Installation**
   - Add Kubernetes repository
   - Install kubectl
   - Configure bash completion

4. **kind Installation**
   - Download latest kind binary
   - Set executable permissions
   - Verify installation

5. **Package Verification**
   - Check all installed packages
   - Display version information

#### Post-Tasks
- Create installation log
- Display completion summary

### Tags for Granular Execution

```bash
# Install only Docker
ansible-playbook install_packages.yml --tags docker

# Install only kubernetes tools
ansible-playbook install_packages.yml --tags kubectl

# Run only verification tasks
ansible-playbook install_packages.yml --tags verify

# Skip Docker installation
ansible-playbook install_packages.yml --skip-tags docker
```

### Handler Management

Handlers are automatically triggered when configuration changes:
- Docker daemon restart on configuration change
- Service state management

---

## 7. Execution Workflow Summary

### Complete Automation Flow

```
1. Preparation
   └─ Install Terraform, AWS CLI, Python, Ansible
   └─ Configure AWS credentials
   └─ Generate SSH key pair

2. Terraform Execution (Terra-1)
   └─ terraform init
   └─ terraform validate
   └─ terraform plan
   └─ terraform apply
   └─ Verify EC2 instances created
   └─ Export inventory.json

3. File Transfer
   └─ Copy inventory.json → Ans-1
   └─ Copy SSH key → Ans-1
   └─ Verify file permissions

4. Ansible Execution (Ans-1)
   └─ Test SSH connectivity (ping)
   └─ ansible-playbook run
   └─ Verify package installation
   └─ Confirm all services running

5. Post-Deployment Validation
   └─ SSH to instances
   └─ Test Docker and kubectl
   └─ Review installation logs
```

### Estimated Execution Time

```
Terraform apply:        5-10 minutes
File transfer:          < 1 minute
Ansible playbook:       10-15 minutes
Total:                  15-25 minutes
```

---

## 8. Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: AWS Credentials Not Found

**Error**: `InvalidUserID.NotFound` or `UnauthorizedOperation`

**Solution**:
```bash
# Verify credentials configured
aws sts get-caller-identity

# Reconfigure if needed
aws configure

# Check credentials file
cat ~/.aws/credentials
cat ~/.aws/config

# Ensure IAM user has required permissions:
# - ec2:CreateInstances
# - ec2:DescribeInstances
# - ec2:CreateSecurityGroup
# - ec2:CreateKeyPair
```

#### Issue 2: SSH Key Permissions Error

**Error**: `ECDSA: Permission denied (publickey)`

**Solution**:
```bash
# Fix key permissions on Terra-1
chmod 600 ~/.ssh/terraform_ec2_key
chmod 644 ~/.ssh/terraform_ec2_key.pub

# Fix key permissions on Ans-1
chmod 600 ~/.ssh/terraform_ec2_key
chmod 700 ~/.ssh

# Verify key content
cat ~/.ssh/terraform_ec2_key.pub
# Should start with 'ssh-rsa' or 'ecdsa-sha2'
```

#### Issue 3: Ansible Cannot Connect to EC2

**Error**: `unreachable: SSH Error: data could not be sent to remote host`

**Solution**:
```bash
# Test SSH connectivity manually
ssh -i ~/.ssh/terraform_ec2_key -v ubuntu@<EC2_PUBLIC_IP>

# Check security group allows SSH
aws ec2 describe-security-groups --group-ids <SG_ID>

# Verify EC2 instance has public IP
aws ec2 describe-instances --instance-ids <INSTANCE_ID> --query 'Reservations[0].Instances[0].[PublicIpAddress,State.Name]'

# Test from Ans-1 VM
ansible all -i inventory/inventory.json -m ping -vvv

# If SSH is slow, add to inventory:
ansible_ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

#### Issue 4: Terraform State Issues

**Error**: `Error acquiring the state lock`

**Solution**:
```bash
# List terraform processes
ps aux | grep terraform

# Kill stuck processes if needed
pkill -f terraform

# Reset state if necessary (CAUTION!)
terraform state list

# Remove stuck resources
terraform state rm aws_instance.ec2

# Manually delete resources in AWS Console if needed
```

#### Issue 5: Package Installation Failures

**Error**: `E: Unable to locate package docker-ce`

**Solution**:
```bash
# On EC2 instances, manually test
sudo apt-get update
sudo apt-get install -y curl

# Check if repositories added correctly
sudo apt-get update

# For Docker specifically:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Re-run playbook with verbose output
ansible-playbook install_packages.yml -i inventory/inventory.json -vvv
```

#### Issue 6: Ansible Module Failures

**Error**: `Failed to validate GPG keys`

**Solution**:
```bash
# Update Python on EC2 instances
ansible all -i inventory/inventory.json -m raw -a "sudo apt-get install -y python3"

# Re-gather facts
ansible all -i inventory/inventory.json -m setup

# Run playbook again
ansible-playbook install_packages.yml -i inventory/inventory.json
```

### Debug Commands

```bash
# Display detailed connection info
ansible all -i inventory/inventory.json -vvv

# Show host variables
ansible all -i inventory/inventory.json -m debug -a "var=hostvars[inventory_hostname]"

# Test specific host
ansible <hostname> -i inventory/inventory.json -m ping

# Execute raw command on all hosts
ansible all -i inventory/inventory.json -m raw -a "uname -a"

# Check Ansible configuration
ansible --version

# Lint playbook for issues
ansible-lint playbooks/install_packages.yml
```

---

## 9. Security Best Practices

### Key Management

```bash
# Generate strong SSH key
ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/terraform_ec2_key -N "passphrase"

# Protect private key
chmod 600 ~/.ssh/terraform_ec2_key
chmod 644 ~/.ssh/terraform_ec2_key.pub

# Never commit to Git
echo "terraform_ec2_key" >> .gitignore

# Rotate keys periodically
ssh-keygen -p -f ~/.ssh/terraform_ec2_key
```

### AWS Best Practices

```hcl
# In terraform.tfvars:
allowed_ssh_cidr = ["YOUR.IP.ADDRESS/32"]  # Not 0.0.0.0/0

# Enable encryption
root_volume_encrypted = true

# Add resource tags for tracking
additional_tags = {
  Owner       = "your-name"
  CostCenter  = "engineering"
  Backup      = "true"
  Compliance  = "required"
}
```

### Ansible Best Practices

```bash
# Use vault for sensitive data
ansible-vault create group_vars/all/vault.yml

# Encrypt playbooks with sensitive data
ansible-playbook install_packages.yml --ask-vault-pass

# Review facts before execution
ansible-playbook install_packages.yml --check --diff

# Limit execution to specific hosts
ansible-playbook install_packages.yml -i inventory/inventory.json -l dev-k8s-cluster-1

# Use become with password prompt
ansible-playbook install_packages.yml --become --ask-become-pass
```

### Terraform State Security

```bash
# Enable state encryption
backend "s3" {
  bucket         = "terraform-state-bucket"
  key            = "prod/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}

# Protect local state
chmod 600 terraform.tfstate
```

---

## Quick Reference Commands

### Terra-1 Commands

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes (safe to run anytime)
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Show outputs
terraform output

# Destroy infrastructure (if needed)
terraform destroy

# Show state
terraform show

# List resources
terraform state list
```

### Ans-1 Commands

```bash
# Test connectivity
ansible all -i inventory/inventory.json -m ping

# Run playbook
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml

# Run with tags
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml --tags docker

# Gather facts
ansible all -i inventory/inventory.json -m setup

# Execute raw command
ansible all -i inventory/inventory.json -m raw -a "docker ps"

# Run in check mode (dry-run)
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml --check
```

---

## Conclusion

This complete setup provides:
✓ Modular, reusable Terraform code
✓ Fully automated EC2 provisioning
✓ Dynamic inventory management
✓ Comprehensive package installation via Ansible
✓ Production-ready configuration
✓ Extensive error handling and validation
✓ Detailed logging and troubleshooting guides

For support:
1. Check Troubleshooting Guide (Section 8)
2. Review logs in ~/terraform/logs/ and ~/ansible/logs/
3. Verify all prerequisites are met
4. Run commands with -v or -vvv for verbose output

---

**Document Version**: 1.0
**Last Updated**: 2024
**Author**: Infrastructure Engineering Team
