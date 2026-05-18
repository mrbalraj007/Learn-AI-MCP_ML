# DevTools Lab — Automated EC2 Provisioning with Terraform & Ansible

A Terraform-based infrastructure-as-code (IaC) project that provisions and configures multi-OS (Linux and Windows) EC2 instances on AWS, automatically generates Ansible inventory, and optionally triggers remote Ansible playbook execution — all from a single `terraform apply`.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Technologies & Tools](#technologies--tools)
3. [Prerequisites](#prerequisites)
4. [Pre-Checks](#pre-checks)
5. [Project Structure](#project-structure)
6. [Configuration Guide](#configuration-guide)
7. [How It Works](#how-it-works)
8. [Advantages](#advantages)
9. [Usage](#usage)
10. [Security Considerations](#security-considerations)

---

## Architecture Overview

```
                          +-------------------+
                          |   Terraform CLI   |
                          |     (>= 1.5)      |
                          +-------+-----------+
                                  |
                    +-------------+-------------+
                    |                           |
            +-------v--------+       +---------v--------+
            |  AWS Provider  |       | TLS/Local/Null   |
            |  (hashicorp/aws|       | Providers        |
            |   ~> 5.0)      |       |                  |
            +-------+--------+       +---------+--------+
                    |                           |
        +-----------+-----------+               |
        |                       |               |
  +-----v------+       +-------v--------+      |
  | Ubuntu     |       | Windows Server |      |
  | 22.04 LTS  |       | 2022           |      |
  | SSH :22    |       | RDP :3389      |      |
  | Python 3   |       | WinRM :5985/86 |      |
  +-----+------+       +-------+--------+      |
        |                       |               |
        +-----------+-----------+               |
                    |                           |
            +-------v--------+          +-------v--------+
            | Ansible        |<---------+ Auto-generated |
            | Inventory      |          | inventory.ini  |
            +-------+--------+          +----------------+
                    |
            +-------v--------+
            | Remote Ansible |
            | Controller     |
            | (optional)     |
            +----------------+
```

### Multi-Platform Support

| Feature | Ubuntu 22.04 | Windows Server 2022 |
|---|---|---|
| Connection | SSH (port 22) | WinRM HTTPS (port 5986) |
| Auth | SSH key pair (4096-bit RSA) | Username/Password |
| Bootstrap | Bash userdata | PowerShell userdata |
| Python | Pre-installed via apt | N/A |
| Ansible Conn | `ansible_connection=ssh` | `ansible_connection=winrm` |

---

## Technologies & Tools

### Infrastructure as Code (IaC)

| Technology | Version | Purpose |
|---|---|---|
| **Terraform** | >= 1.5 | Infrastructure provisioning and state management |
| **HCL** | 2.x | Configuration language for Terraform resources |

### Terraform Providers

| Provider | Source | Version | Purpose |
|---|---|---|---|
| **AWS** | `hashicorp/aws` | ~> 5.0 | EC2 instances, security groups, key pairs, AMI lookup |
| **TLS** | `hashicorp/tls` | ~> 4.0 | RSA 4096-bit private key generation |
| **Local** | `hashicorp/local` | ~> 2.0 | Write key files and inventory to local disk |
| **Null** | `hashicorp/null` | ~> 3.0 | Remote-exec provisioner trigger for Ansible |

### Cloud Provider

| Service | Usage |
|---|---|
| **AWS EC2** | Virtual machine instances (t3.medium) |
| **AWS S3** | Remote Terraform state backend |
| **AWS Security Groups** | Per-instance firewall rules |
| **AWS Key Pairs** | SSH key management for EC2 |

### Operating Systems

| OS | Version | AMI Owner | Use Case |
|---|---|---|---|
| **Ubuntu** | 22.04 LTS (Jammy) | Canonical (`099720109477`) | Linux devtools server |
| **Windows Server** | 2022 English Full Base | Amazon | Windows devtools server |

### Configuration Management

| Technology | Version | Purpose |
|---|---|---|
| **Ansible** | Latest (remote) | Post-provision configuration automation |
| **Ansible Inventory** | INI format | Auto-generated from Terraform state |

### Scripting & Bootstrapping

| Script | Language | Runtime |
|---|---|---|
| Ubuntu userdata | Bash | Cloud-init / boot |
| Windows userdata | PowerShell | Sysprep / boot |
| `script/configure-winrm.ps1` | PowerShell | Windows boot (userdata) |

### Networking & Protocols

| Protocol | Port | OS | Purpose |
|---|---|---|---|
| SSH | 22 | Ubuntu | Secure shell access & Ansible |
| RDP | 3389 | Windows | Remote desktop access |
| WinRM HTTP | 5985 | Windows | Windows Remote Management |
| WinRM HTTPS | 5986 | Windows | Encrypted WinRM (Ansible) |
| ICMP | -1 | Both | Ping / connectivity testing |
| TCP | 30000-32767 | Both | High/ephemeral port range for devtools |

---

## Prerequisites

### Local Machine

- **Terraform** >= 1.5 installed
  ```bash
  terraform --version
  ```
- **Git** (to clone/track changes)
- **AWS CLI** (optional, for manual verification)
  ```bash
  aws --version
  ```
- **Ansible** (optional, for local playbook execution)
  ```bash
  ansible --version
  ```
- **SSH client** (OpenSSH) — pre-installed on Linux/macOS; available via Git Bash/WSL on Windows

### AWS Account

- An active AWS account with programmatic access
- AWS credentials configured via one of:
  - Environment variables: `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
  - AWS credentials file: `~/.aws/credentials`
  - IAM instance profile (if running Terraform from EC2)
- IAM permissions required for the provisioning principal:

  | Service | Permissions |
  |---|---|
  | EC2 | `ec2:DescribeImages`, `ec2:RunInstances`, `ec2:TerminateInstances`, `ec2:CreateSecurityGroup`, `ec2:DeleteSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:CreateKeyPair`, `ec2:DeleteKeyPair`, `ec2:DescribeInstances`, `ec2:DescribeSecurityGroups`, `ec2:RevokeSecurityGroupIngress` |
  | S3 | `s3:GetObject`, `s3:PutObject` (on the state bucket) |

### S3 Backend

- An S3 bucket must exist for remote state storage (configured in `provider.tf`)
  - Default: `demo-terra22062025` in `us-east-1`
  - The bucket must be created before first `terraform init`

### Network

- Internet connectivity from your local machine to AWS API endpoints
- Outbound internet access from EC2 instances (via security group egress rule)
- For Windows instances: port 5986 (WinRM HTTPS) reachable from Ansible controller

---

## Pre-Checks

Run these verifications before deploying.

### 1. Terraform Version

```bash
terraform --version
```

Expected: **Terraform v1.5.0 or higher**

### 2. AWS Credentials

```bash
aws sts get-caller-identity
```

Should return your AWS account ID, user ARN, and account alias. If this fails, configure credentials before proceeding.

### 3. S3 Backend Bucket

```bash
aws s3 ls s3://demo-terra22062025/
```

The bucket must exist. If using a custom bucket name, update the `backend "s3"` block in `provider.tf`.

### 4. AMI Availability

```bash
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId"

aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId"
```

Both should return valid AMI IDs in your configured region.

### 5. Terraform Format & Validate

```bash
terraform fmt -check -recursive
terraform validate
```

Ensures all HCL files are syntactically correct and the configuration is internally consistent.

### 6. SSH Key Check

No existing `devtools-key.pem` should be present (Terraform generates it):

```bash
ls -la devtools-key.*
```

This should return "No such file or directory" on first run. On subsequent runs, these files exist and are managed by Terraform.

### 7. Network Connectivity

```bash
# Test TCP connectivity to AWS EC2 endpoint
curl -s --connect-timeout 5 https://ec2.us-east-1.amazonaws.com/ > /dev/null && echo "OK" || echo "FAIL"
```

---

## Project Structure

```
terraform/
|
|-- main.tf                  # Root module: key pair, EC2 module call, Ansible inventory & trigger
|-- provider.tf              # Terraform & provider configuration, S3 backend
|-- variables.tf             # Input variable declarations with types and defaults
|-- outputs.tf               # Output: instance details and inventory file path
|-- terraform.tfvars         # Variable values (VM definitions) — EDIT THIS
|-- README.md                # This documentation
|
|-- modules/
|   |-- ec2/
|       |-- main.tf          # AMI lookup, security group, userdata, EC2 instance
|       |-- variables.tf     # Module input variables (os_type, instance_type, etc.)
|       |-- outputs.tf       # Module outputs (public_ip, private_ip, os_type, etc.)
|
|-- script/
|   |-- configure-winrm.ps1  # Windows WinRM configuration script (runs at boot via userdata)
|
|-- templates/
|   |-- inventory.ini.tftpl  # Ansible inventory INI template with linux/windows groups
|
|-- .terraform/              # Provider binaries and modules (auto-generated, DO NOT EDIT)
|-- .terraform.lock.hcl      # Provider version lock file (auto-generated)
|-- ansible_inventory.ini    # Generated Ansible inventory (auto-generated)
|-- devtools-key.pem         # Generated private key (auto-generated, chmod 400)
|-- devtools-key.pub         # Generated public key (auto-generated)
```

---

## Configuration Guide

### terraform.tfvars — Defining Your VMs

```hcl
vm_configs = {
  "1" = {
    os_type       = "ubuntu"         # "ubuntu" or "windows"
    instance_type = "t3.medium"      # Any EC2 instance type
    name          = "devtools-server-1"
    # ami_id       = "ami-xxxxxxxxx" # Optional: pin a specific AMI
    # user_data    = "..."           # Optional: custom userdata script
  }
  "2" = {
    os_type       = "windows"
    instance_type = "t3.medium"
    name          = "devtools-server-2"
  }
}
```

### Optional: Remote Ansible Controller

```hcl
ansible_config = {
  host         = "10.0.0.5"
  user         = "ansible"
  ssh_key_path = "~/.ssh/ansible_controller_key"
  project_dir  = "/opt/ansible/devtools"
  venv_path    = "/opt/ansible/venv"  # Optional: Python virtualenv path
  playbook     = "site.yml"
}
```

When set, Terraform will:
1. SCP the generated inventory and private key to the controller
2. Execute `ansible-playbook` with the specified playbook

---

## How It Works

### Step-by-Step Flow

1. **Key Pair Generation** — Terraform generates a 4096-bit RSA key pair via the `tls` provider and uploads the public key as an AWS key pair.

2. **AMI Resolution** — The EC2 module queries AWS for the latest AMI matching each OS type at plan time.

3. **Security Group Creation** — Per-instance security groups are created with OS-specific ingress rules:
   - Ubuntu: SSH (22)
   - Windows: RDP (3389), WinRM HTTP (5985), WinRM HTTPS (5986)
   - Both: ICMP, high ports 30000-32767, full egress

4. **User Data Bootstrap** — Each instance receives an OS-specific bootstrap script at launch:
   - **Ubuntu**: Updates packages, installs Python 3, hardens SSH (disables password auth)
   - **Windows**: Sets Administrator password, enables RDP, runs `script/configure-winrm.ps1` which configures WinRM with HTTPS listener, self-signed certificate, and firewall rules

5. **Instance Launch** — EC2 instances are provisioned with the resolved AMI, security group, key pair, and user data.

6. **Ansible Inventory Generation** — Terraform reads instance IPs and OS types, renders an INI-format inventory via `templates/inventory.ini.tftpl`, and writes it to `ansible_inventory.ini`.

7. **Remote Ansible Trigger** (optional) — If `ansible_config` is defined, Terraform copies the inventory and key to the remote controller and runs the specified playbook.

### WinRM Configuration Details

The `script/configure-winrm.ps1` script (embedded in Windows userdata) performs:

| Step | Description |
|---|---|
| Enable PSRemoting | `Enable-PSRemoting -Force -SkipNetworkProfileCheck` |
| Network Profile | Sets to Private for proper firewall behavior |
| WinRM Timeout | `MaxTimeoutms = 1800000` (30 minutes) |
| Shell Memory | `MaxMemoryPerShellMB = 1024` |
| Auth | Enables Basic auth + unencrypted transport |
| HTTPS Listener | Self-signed certificate + HTTPS listener on port 5986 |
| Firewall Rules | Opens ports 5985 (HTTP) and 5986 (HTTPS) |
| Service Restart | Restarts WinRM to apply all changes |

---

## Advantages

### Automation & Consistency
- **Zero manual setup**: Instances are fully bootstrapped on first boot — no RDP/SSH needed for initial configuration
- **Repeatable infrastructure**: Same configuration produces identical results every time
- **Single command deployment**: `terraform apply` provisions everything end-to-end

### Cross-Platform
- **Unified management**: Linux and Windows instances defined in the same config, deployed simultaneously
- **OS-specific provisioning**: Each OS gets the correct bootstrap script, ports, and Ansible connection type automatically

### State Management
- **Remote state in S3**: Team collaboration without state file conflicts
- **State locking**: Prevents concurrent modifications that could corrupt infrastructure

### Security
- **Auto-generated keys**: 4096-bit RSA keys generated fresh for each deployment
- **SSH hardened**: Password authentication disabled on Linux by default
- **Per-instance security groups**: Network isolation between instances
- **Ephemeral credentials**: Keys are regenerated on `terraform destroy` / re-apply

### Flexibility
- **AMI auto-detection**: Always uses the latest patched AMI unless explicitly pinned
- **Userdata override**: Custom bootstrap scripts per VM without modifying module code
- **Modular design**: EC2 module can be reused across projects
- **Ansible integration**: Optional remote playbook execution or just inventory generation for local use

### Operational Visibility
- **Auto-generated inventory**: Ansible inventory stays in sync with actual infrastructure
- **Rich tagging**: Instances tagged with Name, Environment, Project, OSType, and AnsibleRole
- **Output variables**: IP addresses, OS types, and inventory path exposed after apply

---

## Usage

### Initial Deployment

```bash
# 1. Initialize Terraform (downloads providers, configures backend)
terraform init

# 2. Review the planned changes
terraform plan

# 3. Apply the configuration
terraform apply
```

### Post-Deployment Verification

```bash
# Check generated inventory
cat ansible_inventory.ini

# Test Ansible connectivity
ansible -i ansible_inventory.ini linux -m ping
ansible -i ansible_inventory.ini windows -m win_ping
```

### Adding a New VM

Edit `terraform.tfvars` and add a new entry:

```hcl
vm_configs = {
  # ... existing VMs ...
  "3" = {
    os_type       = "ubuntu"
    instance_type = "t3.large"
    name          = "devtools-server-3"
  }
}
```

Then run:

```bash
terraform plan   # Review
terraform apply  # Deploy
```

### Cleanup

```bash
terraform destroy
```

This removes all EC2 instances, security groups, and local generated files.

---

## Security Considerations

- The Administrator password for Windows (`TempP@ssw0rd123!`) is hardcoded in the module's userdata. For production use, consider using AWS Secrets Manager or SSM Parameter Store.
- WinRM uses a self-signed certificate with certificate validation ignored. For production, use a trusted CA-signed certificate.
- Security group ingress rules use `0.0.0.0/0` for broad accessibility. For production, restrict CIDR ranges to your VPN/office IPs.
- The generated private key (`devtools-key.pem`) is written to the local filesystem. Protect it appropriately and never commit it to version control.
- Consider adding `.pem` and `.pub` files to `.gitignore`.