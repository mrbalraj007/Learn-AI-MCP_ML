# Terraform EC2 + Ansible Infrastructure Automation

**Complete automated solution for provisioning EC2 instances and configuring them with Docker, Kubernetes, and related tools.**

---

## 📋 Project Overview

This project provides a **production-ready, modular, and reusable** solution for:
- **Terraform**: Automatically provisioning EC2 instances on AWS with proper security configurations
- **Ansible**: Automatically configuring instances with Docker, kubectl, kind, and other tools

Perfect for:
- DevOps engineers building Kubernetes testing environments
- Infrastructure teams automating EC2 deployments globally
- Organizations needing consistent, repeatable infrastructure provisioning

---

## 🏗️ Architecture

```
Terraform Server (Terra-1)        Transfer via SCP        Ansible Server (Ans-1)
├── Terraform Configs      ───────────────────────>    ├── Ansible Configs
├── AWS CLI                                             ├── Playbooks
├── SSH Key Pair                                        ├── Dynamic Inventory
└── Generates inventory.json                            └── Execute Installation

        ↓ Provisions                                            ↓ Configures
        
        AWS EC2 Instances (Ubuntu 22.04)
        ├── Public IP assigned
        ├── Security Group configured
        └── Ready for SSH access
        
        After Ansible:
        ├── Docker installed & running
        ├── kubectl installed
        ├── kind installed
        ├── curl, tmux, unzip installed
        └── Services verified & running
```

---

## 📦 What Gets Installed

### System Packages
- `curl` - Data transfer utility
- `wget` - File downloader
- `git` - Version control
- `unzip` - Archive extraction
- `tmux` - Terminal multiplexer
- `htop` - Process monitor
- `jq` - JSON processor

### Container & Kubernetes Tools
- **Docker CE** - Container runtime (v24.0.0)
- **kubectl** - Kubernetes command-line tool
- **kind** - Kubernetes in Docker (v0.20.0)
- **containerd.io** - Container runtime interface
- **docker-compose** - Multi-container orchestration

---

## 🚀 Quick Start

### Prerequisites
- VMware Workstation Pro 17 with two Ubuntu 22.04 VMs (Terra-1 and Ans-1)
- AWS account with credentials
- Network connectivity between VMs and to AWS

### 5-Minute Setup

**On Terra-1:**
```bash
# 1. Setup Terraform
bash setup_terraform.sh

# 2. Configure AWS credentials
aws configure

# 3. Update terraform.tfvars with your public SSH key

# 4. Provision EC2 instances
cd terraform
terraform init
terraform plan
terraform apply

# 5. Export inventory
terraform output
```

**On Ans-1:**
```bash
# 1. Setup Ansible
bash setup_ansible.sh

# 2. Copy files from Terra-1
scp user@terra1:~/terraform/inventory/inventory.json ~/ansible/inventory/
scp user@terra1:~/.ssh/terraform_ec2_key ~/.ssh/

# 3. Fix permissions
chmod 600 ~/.ssh/terraform_ec2_key

# 4. Test connectivity
ansible all -i inventory/inventory.json -m ping

# 5. Run playbook
ansible-playbook -i inventory/inventory.json playbooks/install_packages.yml
```

---

## 📁 Project Structure

```
.
├── terraform/                          # Terraform configurations
│   ├── main.tf                        # Root configuration
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output definitions
│   ├── terraform.tfvars               # Variable values (UPDATE THIS!)
│   ├── modules/
│   │   └── ec2/                       # Reusable EC2 module
│   │       ├── main.tf                # EC2 and security group resources
│   │       ├── variables.tf           # Module variables
│   │       └── outputs.tf             # Module outputs
│   └── inventory/                     # Generated after terraform apply
│       ├── inventory.json             # Dynamic inventory (copy to Ans-1)
│       └── inventory.summary          # Reference file
│
├── ansible/                            # Ansible configurations
│   ├── ansible.cfg                    # Ansible configuration
│   ├── requirements.txt               # Python dependencies
│   ├── inventory/
│   │   ├── hosts.json                # Inventory from Terraform
│   │   ├── inventory.json            # Alternative format
│   │   └── dynamic_inventory.py      # Dynamic inventory script
│   ├── playbooks/
│   │   └── install_packages.yml      # Main installation playbook
│   ├── roles/                        # For future role-based playbooks
│   ├── logs/                         # Ansible execution logs
│   ├── group_vars/                   # Group-level variables
│   └── host_vars/                    # Host-specific variables
│
├── setup_terraform.sh                 # Terraform environment setup script
├── setup_ansible.sh                   # Ansible environment setup script
├── verify_deployment.sh               # Post-deployment verification
├── SETUP_GUIDE.md                     # Detailed setup documentation
├── terraform_ansible_setup_guide.docx # Word document version
└── README.md                          # This file
```

---

## 🔧 Configuration Files Explained

### terraform.tfvars
The **most important file** - customize this for your environment:

```hcl
aws_region              = "us-east-1"           # Your AWS region
environment             = "dev"                 # dev/staging/prod
project_name            = "k8s-cluster"         # Project identifier
instance_type           = "t3.medium"           # EC2 instance type
instance_count          = 2                     # Number of instances
public_key_content      = "ssh-rsa AAAA..."     # Your SSH public key
assign_public_ip        = true                  # Assign public IPs
allowed_ssh_cidr        = ["0.0.0.0/0"]        # Restrict to your IP for security!
root_volume_size        = 30                    # GB
root_volume_encrypted   = true                  # Enable encryption
```

### ansible.cfg
Ansible configuration settings:

```ini
[defaults]
inventory = ./inventory/hosts.json
host_key_checking = False
remote_user = ubuntu
private_key_file = ~/.ssh/terraform_ec2_key.pem
timeout = 30
```

### install_packages.yml
The main Ansible playbook that:
1. Updates system packages
2. Installs Docker and configures daemon
3. Installs Kubernetes tools (kubectl, kind)
4. Installs utility packages (curl, tmux, unzip)
5. Verifies all installations
6. Creates installation logs

---

## 🎯 Usage Examples

### Create 3 t3.large instances in production
```hcl
# In terraform.tfvars:
environment     = "prod"
instance_count  = 3
instance_type   = "t3.large"
root_volume_size = 50
```

### Restrict SSH to your office IP
```hcl
allowed_ssh_cidr = ["203.0.113.0/24"]  # Your company IP range
```

### Deploy to different AWS region
```hcl
aws_region = "eu-west-1"  # London region
```

### Run only Docker installation (skip other packages)
```bash
ansible-playbook install_packages.yml --tags docker
```

### Test without making changes (check mode)
```bash
ansible-playbook install_packages.yml --check --diff
```

### Verify specific host
```bash
ansible dev-k8s-cluster-1 -i inventory/inventory.json -m ping
```

---

## 📊 Execution Timeline

| Phase | Duration | Action |
|-------|----------|--------|
| Terraform Setup | 5-10 min | Install tools, configure AWS |
| Terraform Apply | 5-10 min | Provision EC2 instances |
| File Transfer | <1 min | Copy inventory and SSH key |
| Ansible Setup | 5 min | Install Ansible, configure SSH |
| Playbook Execution | 10-15 min | Install packages on instances |
| **Total** | **20-35 min** | Complete automation |

---

## ✅ Verification Checklist

After deployment, verify everything works:

```bash
# Test Ansible connectivity
ansible all -i inventory/inventory.json -m ping

# Check Docker
ansible all -i inventory/inventory.json -m shell -a "docker --version"

# Check kubectl
ansible all -i inventory/inventory.json -m shell -a "kubectl version --client"

# Check kind
ansible all -i inventory/inventory.json -m shell -a "kind version"

# Connect to instance directly
ssh -i ~/.ssh/terraform_ec2_key ubuntu@<EC2_PUBLIC_IP>

# On EC2 instance
docker ps
docker run hello-world
kubectl version
kind version
```

---

## 🔒 Security Features

✓ **SSH Key-Based Authentication** - No passwords needed
✓ **Encrypted EBS Volumes** - Data at rest encryption
✓ **Security Groups** - Restricted network access
✓ **IAM Integration** - Proper AWS permissions model
✓ **Ansible Vault** - Support for encrypted variables
✓ **SSH Key Rotation** - Easy key pair management
✓ **Audit Logging** - Installation logs on instances

---

## 🚨 Troubleshooting

### "AWS credentials not found"
```bash
aws configure
aws sts get-caller-identity
```

### "SSH: Permission denied"
```bash
chmod 600 ~/.ssh/terraform_ec2_key
chmod 700 ~/.ssh
```

### "Ansible cannot connect to hosts"
```bash
# Test SSH directly
ssh -i ~/.ssh/terraform_ec2_key -v ubuntu@<IP>

# Check security group allows SSH port 22
aws ec2 describe-security-groups --group-ids <SG_ID>
```

### "Packages failed to install"
```bash
# Check system logs
ansible all -i inventory/inventory.json -m shell -a "sudo tail -f /var/log/apt/history.log"

# Update packages manually
ansible all -i inventory/inventory.json -m shell -a "sudo apt-get update"
```

See `SETUP_GUIDE.md` for comprehensive troubleshooting guide.

---

## 🔄 Reusability

### Use the EC2 module in other projects:

```hcl
# terraform/main.tf
module "my_infrastructure" {
  source = "./modules/ec2"
  
  environment     = "staging"
  project_name    = "microservices"
  vpc_id          = aws_vpc.custom.id
  subnet_id       = aws_subnet.custom.id
  ami_id          = data.aws_ami.ubuntu.id
  instance_count  = 5
  instance_type   = "t3.xlarge"
}
```

### Create custom Ansible roles:

```yaml
---
- name: Deploy Custom Application
  hosts: all
  roles:
    - { role: common, tags: ["common"] }
    - { role: docker, tags: ["docker"] }
    - { role: my_app, tags: ["app"] }
```

---

## 📚 Documentation

- **SETUP_GUIDE.md** - Comprehensive step-by-step guide with detailed explanations
- **terraform_ansible_setup_guide.docx** - Professional Word document with formatted guide
- **This README** - Quick reference and overview

---

## 🛠️ Advanced Topics

### Store Terraform state in S3
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Use Ansible Vault for secrets
```bash
ansible-vault create group_vars/all/vault.yml
ansible-playbook playbooks/install_packages.yml --ask-vault-pass
```

### Auto-scale the deployment
```hcl
# Simply change instance_count in terraform.tfvars
instance_count = 10  # Creates 10 instances
```

---

## 📞 Support

For issues or questions:

1. Check the troubleshooting section in `SETUP_GUIDE.md`
2. Review logs:
   - Terraform: `terraform apply` output and state files
   - Ansible: `logs/ansible.log` and `/var/log/package_installation.log` on EC2

3. Enable verbose output:
   - Terraform: `terraform -v` (shows version), `terraform plan -v`
   - Ansible: `ansible-playbook -vvv playbooks/install_packages.yml`

---

## 📝 License

This project is provided as-is for infrastructure automation purposes.

---

## 🎓 Learning Outcomes

Using this project, you'll learn:
- ✓ Terraform module design and reusability
- ✓ AWS EC2 and security group management
- ✓ Ansible inventory and playbook execution
- ✓ SSH key-based authentication
- ✓ Docker and Kubernetes basics
- ✓ CI/CD-ready infrastructure patterns
- ✓ Infrastructure as Code (IaC) best practices

---

## 🚀 Next Steps After Deployment

1. **Test Kubernetes**: Create a local kind cluster
   ```bash
   kind create cluster --name test-cluster
   ```

2. **Deploy applications**: Use kubectl to deploy Docker containers
   ```bash
   kubectl create deployment hello-world --image=hello-world
   ```

3. **Scale infrastructure**: Increase `instance_count` and reapply Terraform
   ```bash
   terraform apply
   ```

4. **Monitor resources**: Use CloudWatch or third-party tools
   ```bash
   aws cloudwatch list-metrics
   ```

---

**Version**: 1.0  
**Last Updated**: 2024  
**Author**: Infrastructure Engineering Team  

For the most up-to-date information, refer to the SETUP_GUIDE.md document.
