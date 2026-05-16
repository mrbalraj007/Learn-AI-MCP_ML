# EC2 + Ansible DevTools Setup

Fully automated provisioning of an Ubuntu 22.04 EC2 instance using **Terraform**, followed by automated package installation using **Ansible dynamic inventory**.

## Packages Installed

| Tool | Method |
|------|--------|
| Docker CE + Compose | Official Docker apt repo |
| kubectl | Official Kubernetes binary |
| kind | GitHub binary release |
| curl | apt |
| unzip | apt |
| tmux | apt |
| git | apt |

---

## Project Structure

```
ec2-ansible-setup/
├── terraform/
│   ├── main.tf                   # EC2, SG, Key Pair, AMI data source
│   ├── variables.tf              # All input variables
│   ├── outputs.tf                # Instance IP, SSH command, etc.
│   └── terraform.tfvars.example  # Copy → terraform.tfvars and edit
│
├── ansible/
│   ├── ansible.cfg               # Ansible config (inventory, SSH, logging)
│   ├── group_vars/
│   │   └── all.yml               # Tool versions, package lists
│   ├── inventory/
│   │   └── aws_ec2.yml           # Dynamic inventory (aws_ec2 plugin)
│   └── playbooks/
│       └── install_packages.yml  # Main playbook — installs all tools
│
├── scripts/
│   ├── deploy.sh                 # ← Run this — full automation
│   └── destroy.sh                # Tears down all AWS resources
│
└── README.md
```

---

## Prerequisites

Install these on your local machine (or CI runner):

```bash
# 1. Terraform >= 1.5
# Download: https://developer.hashicorp.com/terraform/downloads

# 2. Ansible >= 2.14
pip3 install ansible

# 3. AWS SDK for Python (dynamic inventory needs this)
pip3 install boto3 botocore

# 4. Ansible AWS collection
ansible-galaxy collection install amazon.aws

# 5. AWS CLI
pip3 install awscli

# pip3 install ansible boto3 botocore awscli
# ansible-galaxy collection install amazon.aws
```

---

## Quick Start

### Step 1 — Configure AWS credentials

```bash
aws configure
# OR export environment variables:
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2 — Clone / enter project directory

```bash
cd ec2-ansible-setup
```

### Step 3 — Edit Terraform variables (optional)

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit key settings:
#   aws_region       = "ap-southeast-2"   ← your region
#   allowed_ssh_cidr = ["YOUR.IP.HERE/32"] ← your IP (security best practice)
```

### Step 4 — Run the deploy script

```bash
chmod +x scripts/deploy.sh scripts/destroy.sh
./scripts/deploy.sh
```

The script will:
1. ✅ Run preflight checks (tools, AWS credentials, Python libs)
2. 🏗️  `terraform init` → `plan` → `apply` (creates EC2 + key + SG)
3. ⏳  Wait for SSH to become available on the new instance
4. 🔍  Run Ansible dynamic inventory ping test
5. 📦  Run Ansible playbook to install all packages
6. 📋  Print a summary with SSH command

---

## Running Manually (step-by-step)

```bash
# 1. Provision infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan
terraform apply

# 2. Note the public IP
terraform output instance_public_ip

# 3. Test dynamic inventory
cd ../ansible
ansible-inventory -i inventory/aws_ec2.yml --list    # show all discovered hosts
ansible-inventory -i inventory/aws_ec2.yml --graph   # show host groups

# 4. Ping the instance
ansible all -i inventory/aws_ec2.yml -m ping

# 5. Run the playbook
ansible-playbook playbooks/install_packages.yml -i inventory/aws_ec2.yml -v
```

---

## Customisation

### Change tool versions

Edit `ansible/group_vars/all.yml`:

```yaml
kubectl_version: "v1.30.2"   # https://kubernetes.io/releases/
kind_version:    "v0.23.0"   # https://github.com/kubernetes-sigs/kind/releases
```

### Change instance type or region

Edit `terraform/terraform.tfvars`:

```hcl
aws_region    = "us-east-1"
instance_type = "t3.large"
```

### Add more target instances

Tag additional EC2 instances with:
```
Project     = "devtools-lab"
AnsibleRole = "devtools"
```
They will automatically appear in the dynamic inventory.

### Target specific hosts only

```bash
ansible-playbook playbooks/install_packages.yml \
    -i inventory/aws_ec2.yml \
    --limit "role_devtools"
```

---

## Tear Down

```bash
./scripts/destroy.sh
```

This removes the EC2 instance, security group, and key pair from AWS.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `No hosts matched` | Instance not yet `running`, or tags don't match `aws_ec2.yml` filters |
| `SSH permission denied` | Check `devtools-lab-key.pem` exists in `ansible/` and has `chmod 600` |
| `boto3 not found` | Run `pip3 install boto3 botocore` |
| `amazon.aws collection not found` | Run `ansible-galaxy collection install amazon.aws` |
| `No subscriptions found` | AWS credentials not set — run `aws configure` |
| Dynamic inventory empty | Run `ansible-inventory -i inventory/aws_ec2.yml --list` to debug |


*****************

Fix — upgrade the collection to 9.x
```bash
ansible-galaxy collection install 'amazon.aws:>=9.0.0' --force
```
🚀 Step-by-Step Guide
**Step 1 — Install prerequisites on your local machine**
```bash
pip3 install ansible boto3 botocore awscli
ansible-galaxy collection install amazon.aws
```
**Step 2 — Configure AWS credentials**
```bash
aws configure

# OR
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="ap-southeast-2"
```

**Step 3 — Edit your variables**
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```
Change aws_region and optionally restrict allowed_ssh_cidr to your IP (security best practice).

**Step 4 — Run the single deploy script**
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

**This fully automates:**

- ✅ Preflight checks (tools + AWS creds + Python libs)
- 🏗️ terraform init → plan → apply (creates EC2, SG, SSH key)
- ⏳ Waits for SSH to become available
- 🔍 Tests Ansible dynamic inventory ping (falls back to 
static if needed)
- 📦 Runs the playbook — installs Docker, kubectl, kind, curl, unzip, tmux
- 📋 Prints instance IP and ready-to-use SSH command

**Step 5 — Tear down when done**
```bash
./scripts/destroy.sh
```

# 🔑 Key Design Decisions

| Feature | How it works |
|---|---|
| **Dynamic Inventory** | Uses the Ansible `aws_ec2` dynamic inventory plugin with filters: `tag:Project=devtools-lab` and `tag:AnsibleRole=devtools`. Any EC2 instance with these tags is automatically discovered and managed by Ansible. |
| **SSH Key Management** | SSH key pair is automatically generated using Terraform `tls_private_key` resource and stored locally as `ansible/devtools-lab-key.pem`. |
| **Docker Installation** | Docker is installed from the official Docker CE APT repository instead of the default Ubuntu snap package for better compatibility and stability. |
| **kubectl / kind Installation** | `kubectl` and `kind` are downloaded directly from their official binary releases. Installation tasks are idempotent and skip re-download if the correct version already exists. |
| **Idempotent Configuration** | The Ansible playbook is fully idempotent. Re-running the playbook is safe because tasks validate the current state and installed versions before making changes. |