# DevTools Lab — Ansible Automation

**Cross-platform infrastructure automation for Ubuntu Linux and Windows Server 2022 on AWS EC2.**

This project provisions, configures, and maintains a fleet of development servers using Ansible. It supports dynamic AWS inventory, zero-touch Windows WinRM bootstrap, and reusable playbooks for both Linux and Windows targets.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Advantages](#advantages)
- [Prerequisites](#prerequisites)
- [Pre-Flight Checks](#pre-flight-checks)
- [Quick Start](#quick-start)
- [Playbook Reference](#playbook-reference)
- [Inventory Design](#inventory-design)
- [Windows WinRM Bootstrap Strategy](#windows-winrm-bootstrap-strategy)
- [Directory Layout](#directory-layout)
- [Scaling to Large Fleets](#scaling-to-large-fleets)

---

## Project Overview

Two playbooks target a single Ansible group (`devtools`), applying Linux tasks where the OS is Ubuntu and Windows tasks where the OS is Windows Server — all from one `ansible-playbook` invocation.

| Target | OS | Purpose |
|---|---|---|
| `devtools-server-1` | Ubuntu 24.04 LTS | Docker, kubectl, kind, base tools |
| `devtools-server-2` | Windows Server 2022 | IIS Web Server with sample site |

---

## Architecture

```
                    ┌──────────────────────────────────┐
                    │     Ansible Control Node          │
                    │     dc-ops (this machine)         │
                    │     ansible-core 2.17.14          │
                    │     Python 3.10.12                │
                    └────────┬────────────┬────────────┘
                             │            │
                    ┌────────▼──┐    ┌────▼────────────┐
                    │   SSH:22  │    │  WinRM HTTPS    │
                    │           │    │  :5986           │
                    └────────┬──┘    └────┬────────────┘
                             │            │
              ┌──────────────▼──┐  ┌──────▼──────────────┐
              │  Ubuntu 24.04   │  │  Windows Server     │
              │  t3.medium      │  │  2022 t3.medium     │
              │  Docker + k8s   │  │  IIS Web-Server     │
              │  devtools-      │  │  devtools-          │
              │  server-1       │  │  server-2           │
              └─────────────────┘  └─────────────────────┘
                       AWS us-east-1
```

**Key design decisions:**

- **Dynamic inventory** via `amazon.aws.aws_ec2` plugin — servers self-register based on AWS tags. No manual inventory updates.
- **Single group, dual-OS** — the `devtools` group contains both Linux and Windows. Playbooks use facts (`ansible_os_family`, `platform`) to branch logic automatically.
- **Zero-touch Windows bootstrap** — a PowerShell script runs at instance launch (via EC2 userdata) to configure WinRM before Ansible ever connects.

---

## Technology Stack

| Layer | Component | Version |
|---|---|---|
| **CM / Automation** | Ansible (core) | 2.17.14 |
| **Runtime** | Python | 3.10.12 |
| **Cloud** | AWS EC2 | us-east-1 |
| **Linux OS** | Ubuntu | 24.04 LTS |
| **Windows OS** | Windows Server | 2022 |
| **Windows Transport** | WinRM (HTTPS) | port 5986 |
| **Linux Transport** | SSH (key-based) | port 22 |
| **Windows Modules** | `ansible.windows` collection | 2.5.0 |
| **AWS Integration** | `amazon.aws` collection | 11.3.0 |
| **AWS SDK** | boto3 | 1.43.9 |
| **WinRM Library** | pywinrm | 0.5.0 |
| **NTLM Auth** | requests-ntlm | 1.3.0 |
| **Instance Types** | t3.medium (both OS) | — |

### Ansible Collections Used

| Collection | Purpose |
|---|---|
| `ansible.windows` | `win_feature`, `win_service`, `win_file`, `win_copy`, `win_shell` |
| `amazon.aws` | Dynamic EC2 inventory plugin |
| `ansible.posix` | POSIX-level system modules |
| `community.general` | Supplementary modules and filters |

---

## Advantages

### 1. Cross-Platform, Single Pane of Glass
Manage Linux and Windows servers from one control node, one inventory, and one playbook. No separate toolchains or manual hand-offs between OS-specific config management.

### 2. Dynamic AWS Inventory — No Hardcoded IPs
Servers are discovered automatically via AWS tags. Spin up a new instance, tag it correctly, and Ansible picks it up on the next run. 50 servers or 500 — inventory is always current.

### 3. Zero-Touch Windows Provisioning
The WinRM bootstrap is embedded in EC2 userdata. Windows instances configure themselves at first boot. No RDP, no manual PowerShell, no per-server setup — Ansible connects fresh out of provisioning.

### 4. Idempotent, Repeatable, Auditable
Every task is idempotent. Run the same playbook 100 times and only drift gets corrected. Git-versioned playbooks give you a full audit trail of every change applied to every server.

### 5. Declarative, Not Procedural
You declare desired state (IIS installed, Docker running, website present) — Ansible figures out what needs to happen. This eliminates snowflake servers and configuration drift.

### 6. Scales Horizontally Without Additional Tooling
The same playbook that works for 2 servers works for 200. AWS EC2 dynamic inventory + Ansible parallelism (`--forks`) handles fleet-scale operations natively.

### 7. Secure by Default
- Linux: key-based SSH only, no password auth
- Windows: HTTPS WinRM with certificate validation (or explicit opt-out for self-signed lab certs)
- Credentials stay on the control node, never sent to managed hosts

### 8. Minimal Prerequisites on Managed Hosts
- Linux: only SSH + Python3 (already present on Ubuntu AMIs)
- Windows: only WinRM configured (handled by userdata bootstrap)

### 9. Composable for Any Workload
The pattern scales beyond IIS and Docker. Add `community.windows` for Active Directory, `community.docker` for container orchestration, or `kubernetes.core` for cluster management — same inventory, same control node.

### 10. Vendor-Neutral Core, Cloud-Aware Edges
Ansible is cloud-agnostic. The core logic (install packages, deploy files, restart services) stays portable. Cloud-specific concerns (dynamic inventory, security groups) are isolated to configuration files.

---

## Prerequisites

### Ansible Control Node

| Requirement | How to Verify |
|---|---|
| **Ansible >= 2.15** | `ansible --version` |
| **Python >= 3.9** | `python3 --version` |
| **boto3 >= 1.28** | `pip3 show boto3` |
| **pywinrm >= 0.4** | `pip3 show pywinrm` |
| **requests-ntlm** | `pip3 show requests-ntlm` |
| **AWS credentials configured** | `aws sts get-caller-identity` |
| **Ansible collections installed** | `ansible-galaxy collection list` |

Install everything in one go:

```bash
pip3 install ansible boto3 pywinrm "requests-ntlm>=1.2"
ansible-galaxy collection install amazon.aws ansible.windows ansible.posix community.general
```

### AWS Account

| Requirement | Detail |
|---|---|
| **IAM permissions** | `ec2:DescribeInstances` (for dynamic inventory), `ec2:DescribeSecurityGroups`, plus any provisioning permissions for Terraform/CloudFormation |
| **Region** | `us-east-1` (configurable in `inventory/aws_ec2.yml`) |
| **VPC/Subnet** | Public subnets with internet access (or VPC endpoints for SSM-based management) |

### Managed Nodes (Linux)

| Requirement | Detail |
|---|---|
| **AMI** | Ubuntu 24.04 LTS (or any Debian-based AMI with Python 3) |
| **SSH** | Port 22 open in security group |
| **Key pair** | Private key present on control node (`~/.ssh/devtools-key.pem`) |
| **Python** | Present by default on Ubuntu AMIs |

### Managed Nodes (Windows)

| Requirement | Detail |
|---|---|
| **AMI** | Windows Server 2022 Base (Amazon-provided AMI) |
| **WinRM HTTPS** | Port 5986 open in security group |
| **Bootstrap** | `scripts/configure-winrm.ps1` must run at launch (via userdata) |
| **Admin password** | Set via AWS or retrieved via `aws ec2 get-password-data` |

---

## Pre-Flight Checks

Run these before any playbook execution to catch issues early.

### 1. Control Node Readiness

```bash
# Ansible is installed and findable
ansible --version

# Python dependencies are present
python3 -c "import winrm; import boto3; print('OK')"

# AWS credentials are valid
aws sts get-caller-identity

# SSH key exists and has correct permissions (600)
stat -c '%a %U' ~/.ssh/devtools-key.pem
# Expected: 600 dc-ops

# Ansible collections installed
ansible-galaxy collection list | grep -E "amazon.aws|ansible.windows"
```

### 2. AWS Infrastructure

```bash
# Instances are running and tagged correctly
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=devtools-lab" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0],PublicIpAddress]" \
  --output table

# Security groups allow required ports
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=devtools-sg-*" \
  --query "SecurityGroups[*].[GroupName,IpPermissions[*].[FromPort,ToPort,IpRanges[*].CidrIp]]" \
  --output text
```

### 3. Network Connectivity

```bash
# Linux SSH reachable
nc -zv -w 5 <linux-public-ip> 22

# Windows WinRM HTTPS reachable
nc -zv -w 5 <windows-public-ip> 5986

# (Windows RDP reachable — fallback verification)
nc -zv -w 5 <windows-public-ip> 3389
```

### 4. Dynamic Inventory Works

```bash
ansible-inventory --list -i inventory/aws_ec2.yml
# Should output JSON with your running instances grouped under 'linux', 'windows', 'devtools'
```

### 5. Windows WinRM Connection (post-bootstrap)

```bash
ansible windows -i inventory/aws_ec2.yml -m win_ping
# Expected: SUCCESS => { "changed": false, "ping": "pong" }
```

---

## Quick Start

### Step 1 — Provision Infrastructure

Launch two EC2 instances (Terraform, CloudFormation, or AWS Console):

| Setting | Linux | Windows |
|---|---|---|
| AMI | Ubuntu 24.04 LTS | Windows Server 2022 Base |
| Type | t3.medium | t3.medium |
| Key pair | `devtools-key` | `devtools-key` (or password) |
| SG | SSH 22, high ports | RDP 3389, WinRM 5985-5986 |
| Tag `Project` | `devtools-lab` | `devtools-lab` |
| Tag `Environment` | `dev` | `dev` |
| Tag `AnsibleRole` | `linux-devtools` | `windows-devtools` |

**For the Windows instance**, attach this userdata script at launch:

```powershell
<powershell>
# Download and execute the WinRM bootstrap script from your control node
# Alternatively, embed the script content directly
$url = "https://your-artifact-store/configure-winrm.ps1"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($url))

# Or embed inline for self-contained bootstrap:
Set-NetConnectionProfile -NetworkCategory Private
Enable-PSRemoting -Force -SkipNetworkProfileCheck
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
Restart-Service WinRM -Force
</powershell>
```

### Step 2 — Verify Inventory

```bash
ansible-inventory --graph -i inventory/aws_ec2.yml
```

### Step 3 — Test Connectivity

```bash
# Ping all hosts
ansible all -i inventory/aws_ec2.yml -m ping
ansible windows -i inventory/aws_ec2.yml -m win_ping
```

### Step 4 — Run Playbooks

```bash
# Install Linux DevOps tools
ansible-playbook -i inventory/aws_ec2.yml playbooks/ubuntu-install-tools.yml --limit linux

# Install IIS on Windows
ansible-playbook -i inventory/aws_ec2.yml playbooks/windows-install-iis.yml --limit windows

# Or run both at once (playbooks target 'devtools' group by default)
ansible-playbook -i inventory/aws_ec2.yml playbooks/ubuntu-install-tools.yml
ansible-playbook -i inventory/aws_ec2.yml playbooks/windows-install-iis.yml
```

### Step 5 — Validate

```bash
# Linux: Docker is running
ansible linux -i inventory/aws_ec2.yml -m shell -a "docker --version && docker ps"

# Windows: IIS is serving
curl -s http://<windows-public-ip>:80/mysite/
```

---

## Playbook Reference

### `playbooks/ubuntu-install-tools.yml`

Installs a standard DevOps toolchain on Ubuntu servers.

| Step | Module | What It Does |
|---|---|---|
| Update apt cache | `apt` | Refreshes package index |
| Install base packages | `apt` | docker.io, curl, unzip, tmux, make, apt-transport-https |
| Start Docker | `service` | Enables and starts docker daemon |
| Docker group | `user` | Adds `ubuntu` to `docker` group (no `sudo` needed) |
| Install kubectl | `shell` | Downloads and installs latest stable kubectl |
| Install kind | `shell` | Downloads kind v0.29.0 (Kubernetes-in-Docker) |

**Post-run verification:**

```bash
kubectl version --client
kind version
docker run hello-world
```

### `playbooks/windows-install-iis.yml`

Configures WinRM and deploys a test website on Windows Server.

| Step | Module | What It Does |
|---|---|---|
| Configure WinRM listener | `win_shell` | Creates self-signed cert + HTTPS listener on 5986 |
| Enable Basic auth | `win_shell` | Sets Basic=true and AllowUnencrypted=true |
| Open firewall | `win_shell` | Creates WinRM HTTP/HTTPS firewall rules |
| Install IIS | `win_feature` | Installs Web-Server role with management tools |
| Create site directory | `win_file` | `C:\inetpub\wwwroot\mysite` |
| Deploy HTML | `win_copy` | Writes a simple "Hello from IIS" page |
| Start IIS | `win_service` | Ensures W3SVC is running and auto-starts |

---

## Inventory Design

### Static Inventory (`inventory/hosts.ini`)

Used for development/debugging with hardcoded IPs. Generated by Terraform.

```ini
[linux]
devtools-server-1 ansible_host=<ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/devtools-key.pem

[windows]
devtools-server-2 ansible_host=<ip> ansible_user=Administrator ansible_password=<pwd> ansible_connection=winrm ansible_winrm_server_cert_validation=ignore ansible_port=5986 ansible_winrm_scheme=https
```

### Dynamic Inventory (`inventory/aws_ec2.yml`)

The **preferred** inventory for all environments. Discovers instances by AWS tags.

**Filters:**
- `instance-state-name: running`
- `tag:Project: devtools-lab`

**Auto-grouping:**
- `linux` — instances with platform containing "ubuntu" or "linux"
- `windows` — instances with platform == "windows"
- `role_<AnsibleRole value>` — per-role groups (e.g., `role_linux-devtools`)

**Composed connection vars:**
- Linux: `ansible_connection=ssh`, `ansible_user=ubuntu`
- Windows: `ansible_connection=winrm`, `ansible_user=Administrator`

---

## Windows WinRM Bootstrap Strategy

### The Problem

Windows Server 2022 AMIs do not have WinRM HTTPS listening by default. Ansible needs WinRM to connect. You can't configure WinRM over WinRM — this is the classic "Ansible Windows bootstrap problem."

### The Solution — EC2 Userdata

Embed the WinRM configuration script as EC2 userdata. The script executes at first boot (SYSTEM context, elevated), before Ansible ever tries to connect. When Ansible runs, WinRM is already listening.

```
┌──────────────┐     ┌──────────────────┐     ┌───────────────────┐
│ Terraform /  │────▶│ EC2 launches     │────▶│ Userdata fires:   │
│ CloudForm.   │     │ Windows instance │     │ configure-winrm   │
│ provisions   │     │                  │     │ .ps1 runs as      │
│ instance +   │     │                  │     │ SYSTEM on boot    │
│ userdata     │     │                  │     │                   │
└──────────────┘     └──────────────────┘     └────────┬──────────┘
                                                       │
                                                       ▼
┌──────────────┐     ┌──────────────────┐     ┌───────────────────┐
│ Ansible      │◀────│ WinRM HTTPS:5986 │◀────│ Listener created  │
│ win_ping     │     │ Basic auth +     │     │ Firewall opened   │
│   ✓ pong     │     │ self-signed cert │     │ Service running   │
└──────────────┘     └──────────────────┘     └───────────────────┘
```

### What `scripts/configure-winrm.ps1` Does

1. Sets network profile to Private (required for WinRM firewall rules)
2. Enables PSRemoting
3. Configures WinRM: max timeout, max memory, unencrypted traffic, basic auth
4. Creates a self-signed certificate bound to the hostname
5. Creates an HTTPS WinRM listener on port 5986
6. Opens Windows Firewall for ports 5985 and 5986
7. Restarts the WinRM service

### Security Note

Basic auth over self-signed certs is acceptable for dev/test environments behind security groups. For production, consider:
- Domain-joined Windows with Kerberos auth
- Let's Encrypt or internal CA certificates
- Restricting security group inbound rules to the Ansible control node's IP only

---

## Directory Layout

```
ansible/
├── ansible.cfg                      # Ansible configuration
├── inventory/
│   ├── hosts.ini                    # Static inventory (Terraform-generated)
│   └── aws_ec2.yml                  # Dynamic EC2 inventory plugin config
├── playbooks/
│   ├── ubuntu-install-tools.yml     # Linux DevOps toolchain
│   └── windows-install-iis.yml      # Windows IIS + sample site
├── scripts/
│   └── configure-winrm.ps1          # Windows WinRM bootstrap (PowerShell)
└── README.md                        # This file
```

---

## Scaling to Large Fleets

For your 50-server rollout, the workflow is:

1. **Provision 50 instances** via Terraform/CloudFormation — each with the WinRM userdata script attached
2. **Wait for instances to reach `running` state** (Ansible can poll this)
3. **Verify inventory**: `ansible-inventory --graph`
4. **Test connectivity**: `ansible windows -m win_ping` (parallel, defaults to 5 forks)
5. **Run playbooks with higher parallelism**: `ansible-playbook --forks 25 playbooks/windows-install-iis.yml`

Key `ansible.cfg` tunables for fleet scale:

```ini
[defaults]
forks = 25                # Run on 25 hosts in parallel
timeout = 60              # Connection timeout (seconds)
gathering = smart         # Only gather facts when needed
fact_caching = jsonfile   # Cache facts to avoid re-gathering
fact_caching_timeout = 3600
```

No changes needed to playbooks or inventory — the architecture is already fleet-ready.