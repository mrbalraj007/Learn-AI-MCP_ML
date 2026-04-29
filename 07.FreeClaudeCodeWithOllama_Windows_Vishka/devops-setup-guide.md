# Complete DevOps Setup Guide
## Ubuntu 22.04 on VMware Workstation 17 Pro


---

## 📋 Prerequisites — VMware VM Configuration

Before starting, ensure your VM has enough resources:

| Resource | Recommended |
|----------|------------|
| CPUs | 4 vCPUs (min 2) |
| RAM | 8 GB (min 4 GB for Ollama) |
| Disk | 60 GB (Ollama models are large) |
| Network | NAT or Bridged |

```bash
# Once logged into Ubuntu 22.04, update the OS first
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip gnupg software-properties-common \
  ca-certificates apt-transport-https lsb-release build-essential
```

---

## PHASE 1 — Core System Dependencies

### Step 1.1 — Install Node.js 20 LTS (Required for Claude Code & MCP servers)

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

node --version   # Should output v20.x.x
npm --version
```

### Step 1.2 — Install Python 3 + pip + uv (Required for AWS MCP servers)

```bash
sudo apt install -y python3 python3-pip python3-venv python3-dev
pip3 install --upgrade pip

# Install uv (fast Python package manager used by AWS MCP servers)
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env          # Add uv to current session
echo 'source $HOME/.local/bin/env' >> ~/.bashrc

uv --version
```

### Step 1.3 — Install Go (Optional — some MCP servers compile from source)

```bash
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version
```

---



## PHASE 3 — AWS CLI v2

### Step 3.1 — Install AWS CLI v2

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

aws --version   # Should output: aws-cli/2.x.x
```

### Step 3.2 — Configure AWS CLI

```bash
aws configure
# AWS Access Key ID:     <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region:        us-east-1      ← Sydney (Melbourne-closest)
# Default output format: json

# Verify
aws sts get-caller-identity
```

### Step 3.3 — Optional: Configure Named Profiles (for multiple accounts)

```bash

```

---



---

## PHASE 7 — MCP Servers Setup

MCP servers extend Claude Code with real-time tool access (Terraform registry,
AWS APIs, EKS clusters, pricing data). They run as background processes and
are registered in Claude Code's config.

### Architecture Overview

```
Claude Code (CLI / VS Code)
     │
     ├── terraform-mcp       ← HashiCorp Terraform Registry lookups
     ├── aws-core-mcp        ← Core AWS API interactions (IAM, S3, EC2…)
     ├── aws-pricing-mcp     ← Real-time AWS pricing data
     └── aws-eks-mcp         ← EKS cluster management & kubectl ops
```

---

### Step 7.1 — MCP Server 1: terraform-mcp (HashiCorp Official)

Step 1 — Install Go
```bash
sudo tar -C /usr/local -xzf ~/go1.22.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version
```
# Expected: go version go1.22.4 linux/amd64

Build terraform-mcp-server from Source

```sh
git clone https://github.com/hashicorp/terraform-mcp-server.git ~/terraform-mcp-server
cd ~/terraform-mcp-server
go build -o terraform-mcp-server ./cmd/terraform-mcp-server
sudo mv terraform-mcp-server /usr/local/bin/
terraform-mcp-server --help
```
```sh
claude mcp add terraform-mcp -- /usr/local/bin/terraform-mcp-server
```


**MCP Configuration File Locations**
**Primary Config — Where Your 4 MCPs Are Saved**
```bash
cat ~/.claude.json
```
This is your global/home scope config — all 4 MCPs registered from ~ live here.

**All Config Locations Claude Code Uses**

| Scope          | File Location                              | Contains            |
|----------------|--------------------------------------------|---------------------|
| Global / Home  | `~/.claude.json`                            | Your 4 MCPs ✅       |
| Project-level  | `/path/to/project/.claude.json`             | Per-project MCPs    |
| VS Code        | `~/.config/Code/User/settings.json`         | VS Code–specific    |

**Quick Check Commands**
```bash
# View your main MCP config
cat ~/.claude.json

# Pretty print it clearly
python3 -m json.tool ~/.claude.json

# See only the mcpServers section
python3 -c "import json; d=json.load(open('/home/dc-ops/.claude.json')); print(json.dumps(d.get('mcpServers',{}), indent=2))"
```
**Check If Any Project-Level Config Exists**
```bash
# Find all .claude.json files on your system
find ~ -name ".claude.json" 2>/dev/null
```
This will show you every location where MCP configs are saved — including the leftover one inside ~/terraform-mcp-server if you haven't deleted it yet.


**********************************************
```bash
# Download the correct binary directly from GitHub
curl -LO https://github.com/hashicorp/terraform-mcp-server/releases/latest/download/terraform-mcp-server_linux_amd64.tar.gz
tar -xzf terraform-mcp-server_linux_amd64.tar.gz
sudo mv terraform-mcp-server /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform-mcp-server

# Verify
terraform-mcp-server --help

# Cleanup
rm -f terraform-mcp-server_linux_amd64.tar.gz
```

---

### Step 7.2 — MCP Server 2: aws-core-mcp (AWS Labs)

```sh
# Remove the bad file first
rm -f ~/terraform-mcp-server_Linux_x86_64.tar.gz

# Register AWS MCP servers directly (correct syntax)
claude mcp add aws-core-mcp -- uvx awslabs.core-mcp-server@latest
claude mcp add aws-pricing-mcp -- uvx awslabs.cost-explorer-mcp-server@latest
claude mcp add aws-eks-mcp -- uvx awslabs.eks-mcp-server@latest

# Verify
claude mcp list
```

```sh
claude mcp remove aws-core-mcp
claude mcp remove aws-pricing-mcp
claude mcp remove aws-eks-mcp
```
Fix 2 — Check AWS Credentials Exist
```bash
# Check if AWS is configured
aws configure list
aws sts get-caller-identity
```
claude mcp list
claude mcp logs aws-pricing-mcp

















```bash
# AWS Labs MCP servers use Python/uvx
# Install via uv tool (uvx handles the virtual env automatically)
uvx install awslabs.core-mcp-server

# Register with Claude Code
claude mcp add aws-core-mcp \
  --command "uvx" \
  --args "awslabs.core-mcp-server" \
  --env "AWS_REGION=us-east-1" \
  --env "AWS_PROFILE=default"
```

---

### Step 7.3 — MCP Server 3: aws-pricing-mcp (AWS Labs)

```bash
uvx install awslabs.cost-explorer-mcp-server

claude mcp add aws-pricing-mcp \
  --command "uvx" \
  --args "awslabs.cost-explorer-mcp-server" \
  --env "AWS_REGION=us-east-1"
  # NOTE: AWS Pricing API is only available in us-east-1
```

---

### Step 7.4 — MCP Server 4: aws-eks-mcp (AWS Labs)

```bash
# Install kubectl first (EKS MCP requires it)
curl -LO "https://dl.k8s.io/release/$(curl -Ls \
  https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install EKS MCP
uvx install awslabs.eks-mcp-server

claude mcp add aws-eks-mcp \
  --command "uvx" \
  --args "awslabs.eks-mcp-server" \
  --env "AWS_REGION=us-east-1" \
  --env "AWS_PROFILE=default"
```

---

### Step 7.5 — Verify All MCP Servers Are Registered

```bash
claude mcp list
```

Expected output:
```
terraform-mcp    npx @hashicorp/terraform-mcp-server   ● running
aws-core-mcp     uvx awslabs.core-mcp-server            ● running
aws-pricing-mcp  uvx awslabs.cost-explorer-mcp-server         ● running
aws-eks-mcp      uvx awslabs.eks-mcp-server             ● running
```

---

### Step 7.6 — MCP Config File (Manual / Alternative Method)

If `claude mcp add` doesn't persist across sessions, configure manually:

```bash
mkdir -p ~/.config/claude
cat > ~/.config/claude/mcp_config.json <<'EOF'
{
  "mcpServers": {
    "terraform-mcp": {
      "command": "npx",
      "args": ["@hashicorp/terraform-mcp-server"],
      "env": {}
    },
    "aws-core-mcp": {
      "command": "uvx",
      "args": ["awslabs.core-mcp-server"],
      "env": {
        "AWS_REGION": "us-east-1",
        "AWS_PROFILE": "default"
      }
    },
    "aws-pricing-mcp": {
      "command": "uvx",
      "args": ["awslabs.cost-explorer-mcp-server"],
      "env": {
        "AWS_REGION": "us-east-1"
      }
    },
    "aws-eks-mcp": {
      "command": "uvx",
      "args": ["awslabs.eks-mcp-server"],
      "env": {
        "AWS_REGION": "us-east-1",
        "AWS_PROFILE": "default"
      }
    }
  }
}
EOF

echo "✅ MCP config file written"
```

---

## PHASE 8 — VS Code + MCP Integration

### Step 8.1 — Open Workspace in VS Code with Claude

```bash
# Open VS Code
code .

# Inside VS Code, open terminal (Ctrl+`) and start Claude Code
claude
```

### Step 8.2 — VS Code settings.json for MCP

Add to `~/.config/Code/User/settings.json`:

```json
{
  "claude.mcpConfig": "~/.config/claude/mcp_config.json",
  "terminal.integrated.defaultProfile.linux": "bash",
  "terraform.languageServer.enable": true,
  "files.autoSave": "afterDelay"
}
```

---

## PHASE 9 — Final Verification Checklist

Run this verification script to confirm everything works:

```bash
cat > ~/verify-setup.sh <<'SCRIPT'
#!/bin/bash
echo "======================================"
echo "  DevOps Setup Verification"
echo "======================================"

check() {
  if command -v $1 &>/dev/null; then
    echo "✅ $1 — $($1 --version 2>&1 | head -1)"
  else
    echo "❌ $1 — NOT FOUND"
  fi
}

check node
check npm
check python3
check pip3
check uv
check code
check aws
check terraform
check kubectl
check ollama
check claude

echo ""
echo "--- Ollama Models ---"
ollama list 2>/dev/null || echo "Ollama not running"

echo ""
echo "--- Claude MCP Servers ---"
claude mcp list 2>/dev/null || echo "Not authenticated or Claude not installed"

echo ""
echo "--- AWS Identity ---"
aws sts get-caller-identity 2>/dev/null || echo "AWS not configured"

echo "======================================"
SCRIPT

chmod +x ~/verify-setup.sh
~/verify-setup.sh
```

---

## PHASE 10 — Troubleshooting

### Issue: `uvx` command not found after install
```bash
source $HOME/.local/bin/env
# Or add to .bashrc:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: Ollama model download too slow on VM
```bash
# Increase timeout, run in background
nohup ollama pull qwen2.5:7b &
tail -f nohup.out
```

### Issue: Claude Code auth fails behind corporate proxy
```bash
export HTTPS_PROXY=http://<proxy-host>:<port>
export HTTP_PROXY=http://<proxy-host>:<port>
export NO_PROXY=localhost,127.0.0.1,169.254.169.254
claude login
```

### Issue: MCP server fails to start
```bash
# Check logs
claude mcp logs terraform-mcp
claude mcp logs aws-core-mcp

# Restart a specific MCP
claude mcp restart aws-eks-mcp

# Check uvx can resolve the package
uvx awslabs.core-mcp-server --help
```

### Issue: AWS MCP can't authenticate
```bash
# Ensure AWS credentials are exported (uvx inherits env)
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
export AWS_DEFAULT_REGION=us-east-1
```

### Issue: VMware clipboard / copy-paste not working
```bash
sudo apt install -y open-vm-tools open-vm-tools-desktop
sudo reboot
```

---

## Quick Reference Summary

| Component         | Install Method     | Config Location                        |
|-------------------|--------------------|----------------------------------------|
| Node.js 20        | nodesource apt     | system                                 |
| Python + uv       | apt + curl         | ~/.local/bin                           |
| VS Code           | Microsoft apt repo | ~/.config/Code/User/settings.json      |
| AWS CLI v2        | official installer | ~/.aws/credentials, ~/.aws/config      |
| Terraform         | hashicorp apt      | ~/.terraform.d/                        |
| Ollama            | install.sh         | /etc/systemd/system/ollama.service     |
| Claude Code       | npm global         | ~/.config/claude/                      |
| terraform-mcp     | npx (npm)          | ~/.config/claude/mcp_config.json       |
| aws-core-mcp      | uvx (Python)       | ~/.config/claude/mcp_config.json       |
| aws-pricing-mcp   | uvx (Python)       | ~/.config/claude/mcp_config.json       |
| aws-eks-mcp       | uvx (Python)       | ~/.config/claude/mcp_config.json       |


several installers leave behind tarballs, zip files, setup scripts, and package caches. Here's a dedicated cleanup script that covers everything from the guide:

# Cleaned Items and Why They’re Safe to Delete

| What’s Cleaned | Why It’s Safe to Delete |
|---------------|------------------------|
| `awscliv2.zip` + `aws/` folder | AWS CLI is already installed to `/usr/local/aws-cli/2` |
| `go1.*.tar.gz` | Go is already extracted to `/usr/local/go/` |
| `~/kubectl` file | Already moved to `/usr/local/bin/kubectl` |
| APT cache + orphaned packages | `apt autoremove` removes unused dependency libraries |
| npm cache | Packages are already installed globally; cache is only for re-downloads |
| pip cache | Cached wheels only; installed packages remain intact |
| uv cache | MCP servers already installed; `uvx` caches package downloads |
| Old Snap revisions | Ubuntu keeps multiple old Snap versions by default, which wastes space |
| Thumbnails, Trash, `/tmp` | Standard OS-generated temporary and junk files |


