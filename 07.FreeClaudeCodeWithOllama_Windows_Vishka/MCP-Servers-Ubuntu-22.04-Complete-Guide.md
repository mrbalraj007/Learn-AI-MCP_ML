# Complete MCP Servers Configuration Guide

## Ubuntu 22.04 LTS + Claude Code + Ollama + uvx MCP Servers 

<!-- **Last Updated:** April 2026   -->
**Status:** ✅ Tested & Verified Working  
**Scope:** Production-ready MCP setup with proper error handling

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Phase 1: Prerequisites & Validation](#phase-1-prerequisites--validation)
3. [Phase 2: Install Core Dependencies](#phase-2-install-core-dependencies)
4. [Phase 3: Configure MCP Servers](#phase-3-configure-mcp-servers)
5. [Phase 4: Verification & Testing](#phase-4-verification--testing)
6. [Phase 5: Troubleshooting](#phase-5-troubleshooting)
7. [Advanced Configuration](#advanced-configuration)

---

## Architecture Overview

### System Topology

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code (CLI)                    │
│                  Your AI Coding Agent                   │
└────────────┬────────────────────────────┬────────────────┘
             │                            │
      ┌──────▼──────┐              ┌──────▼──────┐
      │ Ollama       │              │ MCP Servers │
      │ (Local LLM)  │              │ (via uvx)   │
      └──────────────┘              └──────┬──────┘
                                           │
         ┌─────────────┬───────────────────┼───────────────┐
         │             │                   │               │
    ┌────▼────┐  ┌────▼────┐  ┌────────▼───────┐  ┌─────▼─────┐
    │Terraform│  │AWS Core  │  │AWS Pricing &   │  │EKS        │
    │MCP      │  │MCP       │  │Cost Explorer   │  │MCP        │
    │         │  │(APIs)    │  │MCP             │  │           │
    └─────────┘  └──────────┘  └────────────────┘  └───────────┘
       TTL        Core AWS      Cost Analysis      Kubernetes
     Registry    Operations     & Optimization     Management
```
### Tools: 
- VS Code
- Claude Code
- Ollama
- Terraform
- AWS CLI
- MCP Servers
- Docker
- Docker-compose


### MCP Server Details

| Server | Type | Package | Purpose | Requires |
|--------|------|---------|---------|----------|
| **terraform-mcp** | Registry | awslabs.terraform-mcp-server | Terraform provider/module queries | - |
| **aws-core-mcp** | Python/uvx | awslabs.core-mcp-server | EC2, S3, IAM, VPC operations | AWS Credentials |
| **aws-pricing-mcp** | Python/uvx | awslabs.cost-explorer-mcp-server | Real-time pricing, cost analysis | AWS Credentials |
| **eks-mcp** | Python/uvx | awslabs.eks-mcp-server | EKS cluster management | AWS Creds + kubectl |

---

## Phase 1: Prerequisites & Validation

### Step  1.1 System Requirements

```bash
# Verify Ubuntu version
lsb_release -a
# Expected: Ubuntu 22.04 LTS

# Check available disk space (need at least 20GB free)
df -h /
# Look for "Avail" column

# Check RAM (minimum 4GB for basic setup, 8GB recommended)
free -h
# Look at "Mem:" line

# Verify internet connectivity
curl -I https://github.com
# Should return HTTP 200 or 301
```

### Step 1.2 Pre-flight Checks

```bash
#!/bin/bash
# Run this to verify prerequisites before starting

echo "=== UBUNTU 22.04 MCP SETUP VALIDATION ==="
echo ""

# 1. Check OS
if [[ $(lsb_release -rs) == "22.04" ]]; then
    echo "✅ Ubuntu 22.04 detected"
else
    echo "❌ Not Ubuntu 22.04 - may cause issues"
fi

# 2. Check essential commands
for cmd in curl wget git python3 pip3; do
    if command -v $cmd &>/dev/null; then
        echo "✅ $cmd installed"
    else
        echo "❌ $cmd NOT installed"
    fi
done

# 3. Check Claude Code
if command -v claude &>/dev/null; then
    echo "✅ Claude Code CLI installed: $(claude --version)"
else
    echo "❌ Claude Code not installed"
fi

# 4. Check Ollama
if command -v ollama &>/dev/null; then
    echo "✅ Ollama installed"
    curl -s http://localhost:11434/api/tags >/dev/null 2>&1 && \
        echo "✅ Ollama service running" || \
        echo "⚠️  Ollama not running (start with: ollama serve &)"
else
    echo "❌ Ollama not installed"
fi

# 5. Check uv/uvx
if command -v uv &>/dev/null; then
    echo "✅ uv installed: $(uv --version)"
else
    echo "⚠️  uv not installed (required for MCP servers)"
fi

# 6. Check AWS CLI
if command -v aws &>/dev/null; then
    echo "✅ AWS CLI installed: $(aws --version 2>&1 | head -1)"
    aws sts get-caller-identity >/dev/null 2>&1 && \
        echo "✅ AWS credentials configured" || \
        echo "⚠️  AWS credentials not configured (run: aws configure)"
else
    echo "⚠️  AWS CLI not installed (optional but recommended)"
fi

# 7. Check kubectl
if command -v kubectl &>/dev/null; then
    echo "✅ kubectl installed: $(kubectl version --client 2>&1 | head -1)"
else
    echo "⚠️  kubectl not installed (only needed for EKS MCP)"
fi

echo ""
echo "=== END VALIDATION ==="
```

Save as `validate-setup.sh` and run:
```bash
chmod +x validate-setup.sh
./validate-setup.sh
```

---

## Phase 2: Install Core Dependencies

### Step 2.1 Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    gnupg \
    lsb-release
```

### Step 2.2 Install/Verify Node.js (for Claude Code)

```bash
# Check if already installed
node --version   # Should be v18+ 
npm --version    # Should be 9+

# If not installed, add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify
node --version   # v20.x.x
npm --version    # 10.x.x+
```

### Step 2.3 Install uv (Critical for MCP Servers)

**uv is a blazingly fast Python package installer** that manages uvx (virtual environments for single commands).

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
uv --version
# Expected: uv 0.x.x

# Verify uvx works
uvx --help
# Should show uvx usage
```

**Why uv?**
- 10-100x faster than pip
- Automatic virtual environment management
- No installation pollution
- Perfect for MCP servers

### Step 2.4 Install AWS CLI v2

```bash
# Download AWS CLI v2
# curl "https://awscli.amazonaws.com/awscliv2.zip" -o "awscliv2.zip"

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Extract
unzip awscliv2.zip

# Install
sudo ./aws/install

# Verify
aws --version
# Expected: aws-cli/2.x.x

# Cleanup
rm -rf aws awscliv2.zip
```

### Step 2.5 Configure AWS Credentials

```bash
# Configure AWS (requires IAM Access Key + Secret)
aws configure --profile default

# When prompted, enter:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region: us-east-1           # IMPORTANT: Pricing API only in us-east-1
# Default output format: json

# Verify credentials work
aws sts get-caller-identity

# Example output:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-user"
# }

# Example: separate profile per environment
aws configure --profile tge-prod
aws configure --profile tge-nonprod

# Use a profile
export AWS_PROFILE=tge-prod
aws sts get-caller-identity

```

> **⚠️ Important:** AWS Pricing API only available in `us-east-1`. Always use this region for aws-pricing-mcp.

### Step 2.6 Install kubectl (for EKS MCP only)

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
# Expected: Client Version: v1.x.x
```

### Step 2.7 Verify All Dependencies

```bash
# Quick check
echo "=== DEPENDENCY CHECK ==="
command -v claude && echo "✅ Claude Code" || echo "❌ Claude Code"
command -v ollama && echo "✅ Ollama" || echo "❌ Ollama"
command -v uv && echo "✅ uv" || echo "❌ uv"
command -v aws && echo "✅ AWS CLI" || echo "❌ AWS CLI"
command -v kubectl && echo "✅ kubectl" || echo "❌ kubectl"
echo ""

# Test uv/uvx
uvx python --version
# Should output: Python 3.x.x
```
---
## 🐳 Phase 3: Install Docker

### Step 3.1 Remove old Docker versions (if any)

```bash
sudo apt remove docker docker-doc docker.io containerd runc -y
```

This cleans up any existing Docker installations that might conflict.

### Step 3.2 Install Docker's dependency packages

```bash
sudo apt install ca-certificates curl gnupg lsb-release -y
```

These are required for secure Docker installation.

### Step 3.3 Add Docker's GPG key

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

This verifies that packages come from Docker's official repository.

### Step 3.4 Set up Docker's APT repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

This adds Docker's official Ubuntu repository.

### Step 3.5 Install Docker Engine

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

**What we're installing:**
- `docker-ce`: Docker Community Edition (the main engine)
- `docker-cli`: Command-line interface
- `containerd.io`: Container runtime
- `docker-compose-plugin`: For multi-container setups

### Step 3.6 Add user to the Docker group

```bash
sudo usermod -aG docker $USER
```

This allows you to run Docker commands without `sudo`.

### Step 3.7 Refresh user permission to the Docker group

```bash
newgrp docker
```

> [!IMPORTANT]
If abobe doesn't work then log out and log back in (or restart) for this to take effect.

### Step 3.8 Verify Docker Service

After installation, verify that Docker is running:

```bash
docker --version
```

**Expected output:**
```
Docker version 29.x.x (or newer)
```

**If Docker is not running, start it manually:**

```bash
sudo systemctl start docker
```

<img width="1711" height="495" alt="Image" src="https://github.com/user-attachments/assets/2c222c3e-1ce7-4458-9fd0-72b83b1e1e5e" />

---

## PHASE 4 — VS Code

### Step 4.1 — Install VS Code

```bash
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor \
  | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list

sudo apt update && sudo apt install -y code
code --version
```

### Step 4.2 — Install Recommended VS Code Extensions

```bash
# Terraform / IaC
code --install-extension hashicorp.terraform
code --install-extension hashicorp.hcl

# AWS
code --install-extension amazonwebservices.aws-toolkit-vscode

# General DevOps
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-azuretools.vscode-docker
code --install-extension redhat.vscode-yaml
code --install-extension ms-python.python
code --install-extension github.copilot          # optional
code --install-extension eamodio.gitlens

echo "✅ VS Code extensions installed"
```

---

## PHASE 5 — Terraform

### Step 5.1 — Install Terraform via HashiCorp repo

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y terraform
terraform version
```

### Step 5.2 — Install tfenv (optional — manage multiple Terraform versions)

```bash
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

tfenv install 1.8.5
tfenv use 1.8.5
terraform version
```

### Step 5.3 — Verify Terraform is working

```bash
mkdir -p ~/terraform-test && cd ~/terraform-test
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
EOF

terraform init
echo "✅ Terraform working"
cd ~ && rm -rf ~/terraform-test
```

---

## PHASE 6 — Ollama + Qwen Model

### 🧠 Step 6.1: Install Ollama (Local LLM)

### Step 6.1 What is Ollama?

Ollama lets you run large language models locally on your machine. No cloud dependencies, no API costs, no internet required for inference. Perfect for development and testing without hitting rate limits.

### Step 6.2 Download and install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama --version
```

### Step 6.3 — Start Ollama Service

```bash
# Enable as systemd service (auto-starts on boot)
sudo systemctl enable ollama
sudo systemctl start ollama
sudo systemctl status ollama
```
### Step 6.4 Verify installation

```bash
ollama --version
```

**Expected output:**
```
ollama version is 0.21.x
```

### Step 6.5 Pull Models for Coding

```bash
# Cloud models (no local resource usage)
ollama pull qwen3.5:cloud       # Fast cloud variant
ollama pull kimi-k2.5:cloud     # High quality reasoning

# Local models (recommended for coding)
ollama pull qwen2.5-coder:7b    # Lightweight, 7B parameters
ollama pull qwen3.5:9b          # Better quality, 9B parameters
ollama pull deepseek-coder:6.7b # Specialized for code

# List all pulled models
ollama list
```

**Model Selection Guide:**

| Model | Size | RAM | Quality | Speed | Local/Cloud |
|-------|------|-----|---------|-------|------------|
| qwen2.5-coder:7b | 4.7GB | 8GB | Good | Fast | Local |
| qwen3.5:9b | 5.5GB | 12GB | Very Good | Medium | Local |
| deepseek-coder:6.7b | 3.8GB | 8GB | Good | Fast | Local |
| qwen3.5:cloud | - | 0 | Very Good | Fast | Cloud |
| kimi-k2.5:cloud | - | 0 | Excellent | Medium | Cloud |

### Step 6.6 — Pull and Run Qwen Model

```bash
# Pull Qwen2.5 (3B for low RAM, 7B for better quality)
# NOTE: qwen3.5:cloud is not an Ollama tag — use qwen2.5 series
ollama pull qwen2.5:7b         # 7B model (~4.7 GB)
# OR for lower RAM VMs:
# ollama pull qwen2.5:3b       # 3B model (~2.0 GB)

# Run the model interactively
ollama run qwen2.5:7b

# >>> exit from prompt and then run the below

# Test via API
curl http://localhost:11434/api/generate \
  -d '{"model": "qwen2.5:7b", "prompt": "Hello, who are you?", "stream": false}'
```

### Step 6.7 — List Installed Models

```bash
ollama list
```

> **Note on model name:** `qwen3.5:cloud` is not a valid Ollama tag at time of writing.
> Use `qwen2.5:7b` or check https://ollama.com/library/qwen2.5 for current tags.
> Once Qwen3 is available on Ollama, it will appear as `qwen3:latest` etc.

### 6.8 Sign in to Ollama using the CLI

**Step 6.8.1. Run the login command**
```Shell
ollama login
```

**Step 6.8.2. Complete browser authentication**

After running the command, Ollama will:

- Open your **default web browser**, or <br>
- Display a **URL** to open manually

- You’ll be asked to:

  - Sign in with your Ollama account (GitHub / Google / email)
  - Approve CLI access

✅ Once approved, the CLI session is authenticated automatically.

**Step 6.8.3. Verify you’re signed in**
Run:
```Shell
ollama whoami
```
Example output:
```sh
username@example.com
```

**Step 6.8.4. Run a Cloud model and Test the model locally**
Now Cloud models will work:

Try a quick inference to make sure it's working:

```bash
ollama run qwen3.5:cloud "Write a simple Hello World in Terraform"
```

The model should respond with Terraform code. If it works, you're good to go.

<img width="1718" height="905" alt="Image" src="https://github.com/user-attachments/assets/46c394ba-9bca-43be-8f42-b06e52411b25" />

---

## PHASE 7 — Claude Code (CLI)

### Step 7.1 — Install Claude Code

```bash
# npm install -g @anthropic-ai/claude-code

# Download and install native Claude Code binary
curl -fsSL https://claude.ai/install.sh | bash

# Verify Claude Version
claude --version
```

> [!CAUTION]
**Fix:** *If you are using npm to install claude then follow below*

The Problem — npm EACCES Permission Error
Your Node.js was installed via apt (system package), so /usr/lib/node_modules is owned by root. Running npm install -g as a regular user fails. Never use sudo npm install -g — that's a security risk.
```sh
# Step 1 — Create a user-owned npm global directory
mkdir -p ~/.npm-global

# Step 2 — Tell npm to use it
npm config set prefix '~/.npm-global'

# Step 3 — Add it to your PATH
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Step 4 — Verify npm now points to user directory
npm config get prefix
# Should output: /home/dc-ops/.npm-global
```
**Why This Happens**

| Install Method | Global Dir | Owned By |
|---------------|------------|----------|
| `apt install nodejs` | `/usr/lib/node_modules` | `root` ❌ |
| After fix above | `~/.npm-global` | `dc-ops` ✅ |


### Step 7.2 — Authenticate Claude Code

```bash
# This opens a browser for Anthropic login
ollama launch claude
#claude login

# Verify auth
# claude whoami
```

### Step 7.3 — Test Claude Code

```bash
mkdir -p ~/claude-test && cd ~/claude-test
claude "List all files in this directory and explain what each does"
cd ~
```


---

## Phase 8: Configure MCP Servers

### Overview: Adding MCP Servers to Claude Code

The `claude mcp add` command registers servers in `~/.claude.json` (global) or project-level `.claude.json`.

**Command Syntax:**
```bash
claude mcp add <server-name> \
  [--scope <user|workspace>] \
  [-e KEY=VALUE] \
  -- <command> [args...]
```

**Parameters:**
- `<server-name>`: Human-readable name (e.g., `aws-pricing-mcp`)
- `--scope user`: Saves to `~/.claude.json` (global)
- `--scope workspace`: Saves to project `.claude.json`
- `-e KEY=VALUE`: Environment variable (repeatable)
- `-- <command>`: The command to run (uvx, npx, etc.)

---

### Step 8.1 `MCP Server 1`: Terraform Registry (terraform-mcp)

**Purpose:** Query Terraform Registry for providers and modules  
**Package:** `awslabs.terraform-mcp-server`  
**Installs via:** uvx  
**Requirements:** None (no credentials needed)

```bash
# Add Terraform MCP Server to Claude Code
claude mcp add terraform-mcp \
  --scope user \
  -- uvx awslabs.terraform-mcp-server@latest

# Verify it was added
cat ~/.claude.json | grep -A 5 '"terraform-mcp"'

# Expected config structure:
# "terraform-mcp": {
#   "command": "uvx",
#   "args": ["awslabs.terraform-mcp-server@latest"]
# }
```

**Test in Claude Code:**
```bash
# Start Claude Code
claude

# Inside Claude Code terminal:
/mcp
# Should show: terraform-mcp ✓ Connected

# Ask Claude:
# "Show me the latest AWS Terraform provider version"
# It will query the Terraform Registry
```

---

### Step 8.2 `MCP Server 2`: AWS Core Operations (aws-core-mcp)

**Purpose:** Core AWS API operations (EC2, S3, IAM, VPC, etc.)  
**Package:** `awslabs.core-mcp-server`  
**Installs via:** uvx  
**Requirements:** AWS credentials configured

```bash
# Add AWS Core MCP Server with environment variables
claude mcp add aws-core-mcp \
  --scope user \
  -e AWS_REGION=us-east-1 \
  -e AWS_PROFILE=default \
  -- uvx awslabs.core-mcp-server@latest

# Verify
cat ~/.claude.json | grep -A 10 '"aws-core-mcp"'

# Expected output shows environment variables:
# "aws-core-mcp": {
#   "command": "uvx",
#   "args": ["awslabs.core-mcp-server@latest"],
#   "env": {
#     "AWS_REGION": "us-east-1",
#     "AWS_PROFILE": "default"
#   }
# }
```

**Test in Claude Code:**
```bash
claude

# Inside Claude Code:
/mcp
# Should show: aws-core-mcp ✓ Connected

# Ask Claude:
# "List all EC2 instances in my AWS account"
# "Show me my S3 buckets"
# "What's my AWS account ID?"
```

---

### Step 8.3 `MCP Server 3`: AWS Pricing & Cost Analysis (aws-pricing-mcp)

**Purpose:** Real-time AWS pricing data, cost estimation, cost analysis  
**Package:** `awslabs.cost-explorer-mcp-server`  
**Installs via:** uvx  
**Requirements:** AWS credentials configured, **MUST use us-east-1**

```bash
# Add AWS Pricing/Cost Explorer MCP Server
# ⚠️ IMPORTANT: AWS Pricing API only works in us-east-1
claude mcp add aws-pricing-mcp \
  --scope user \
  -e AWS_REGION=us-east-1 \
  -e AWS_PROFILE=default \
  -- uvx awslabs.cost-explorer-mcp-server@latest

# Verify
cat ~/.claude.json | grep -A 10 '"aws-pricing-mcp"'

# Note: AWS_REGION MUST be us-east-1 (Pricing API limitation)

# Check if environment variables are set in your shell
echo $AWS_PROFILE
echo $AWS_REGION

# If empty, add to ~/.bashrc
echo 'export AWS_PROFILE=default' >> ~/.bashrc
echo 'export AWS_REGION=us-east-1' >> ~/.bashrc
source ~/.bashrc

# Verify
echo $AWS_PROFILE    # Should output: default
echo $AWS_REGION     # Should output: us-east-1
```

**Test in Claude Code:**
```bash
claude

# Inside Claude Code:
/mcp
# Should show: aws-pricing-mcp ✓ Connected

# Ask Claude:
# "What's the monthly cost for 10 t3.large EC2 instances?"
# "Estimate the cost of my current infrastructure"
# "Compare pricing between instance types"
```

---

### Step 8.4 `MCP Server 4`: EKS Cluster Management (eks-mcp)

**Purpose:** Query and manage EKS clusters, deployments, pods, troubleshooting  
**Package:** `awslabs.eks-mcp-server`  
**Installs via:** uvx  
**Requirements:** AWS credentials, kubectl installed, kubeconfig configured

#### Step 8.4.1: Configure kubectl for EKS Access

```bash
# If you have an EKS cluster, configure kubectl access
aws eks update-kubeconfig \
  --name YOUR_CLUSTER_NAME \
  --region us-east-1 \
  --profile default

# Verify kubectl can access your cluster
kubectl cluster-info
kubectl get nodes

# Expected: Lists your EKS nodes
```

#### Step 8.4.2: Add EKS `MCP Server`

```bash
# Add EKS MCP Server
claude mcp add eks-mcp \
  --scope user \
  -e AWS_REGION=us-east-1 \
  -e AWS_PROFILE=default \
  -- uvx awslabs.eks-mcp-server@latest

# Verify
cat ~/.claude.json | grep -A 10 '"eks-mcp"'
```

**Test in Claude Code:**
```bash
claude

# Inside Claude Code:
/mcp
# Should show: eks-mcp ✓ Connected

# Ask Claude (requires active EKS cluster):
# "List all pods in the default namespace"
# "Show me my deployments and their status"
# "What's the CPU and memory usage of my pods?"
```

---

### Step 8.5 Verify All `MCP Servers` Are Registered

```bash
# View your complete MCP configuration
cat ~/.claude.json

# Pretty-print for readability
python3 -m json.tool ~/.claude.json | grep -A 5 "mcpServers"

# Expected: 4 servers should be listed:
# - terraform-mcp
# - aws-core-mcp
# - aws-pricing-mcp
# - eks-mcp
```
---

> [!IMPORTANT]
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
This will show you every location where MCP configs are saved 

<!-- — including the leftover one inside ~/terraform-mcp-server if you haven't deleted it yet. -->

---
### Step 8.6 Create CLAUDE.md for Project Guidelines

```bash
cat > CLAUDE.md << 'EOF'
# Claude Code Project Configuration

## Model Selection
- Use local: `qwen2.5-coder:7b` for fast, cost-free coding
- Use cloud: `qwen3.5:cloud` for better quality/complex tasks
- Use `deepseek-coder:6.7b` for specialized code generation

## MCP Server Routing
- **aws-pricing**: Cost estimation for IaC projects
  - Available tools: get_pricing, generate_cost_report, analyze_terraform_project
  
- **terraform-mcp**: Terraform Registry integration
  - Available tools: Terraform provider/module queries
  
- **eks-mcp**: EKS cluster management
  - Available tools: Cluster info, deployments, troubleshooting
  - Requires: AWS CLI + kubeconfig configured

## Recommended Workflows
1. **IaC Design Review**: aws-pricing + terraform-mcp
2. **Kubernetes Operations**: eks-mcp (requires active cluster)
3. **Cost Optimization**: aws-pricing analyze_terraform_project

## Permissions
All MCP tools require approval by default. Type 'y' to approve, 'n' to skip.
To auto-approve in dev: `--dangerously-skip-permissions` (testing only)
EOF
```

### Step 8.7 Create Alias for Quick Launch

```bash
cat >> ~/.bashrc << 'EOF'

# Claude Code aliases
alias claude-local='ollama launch claude --model qwen2.5-coder:7b'
alias claude-cloud='ollama launch claude --model qwen3.5:cloud'
alias claude-fast='ollama launch claude --model deepseek-coder:6.7b'
EOF

source ~/.bashrc
```

---

## Phase 9: Testing & Validation

### Step 9.1 Test Local LLM (Ollama)

```bash
# Launch Claude Code with local model
claude-local

# Inside Claude Code terminal, test basic operation:
# Type: /init
# Then ask: "Create a hello world Python script"
```

### Step 9.2 Test AWS Pricing MCP

```bash
# Inside Claude Code:
# Type: /mcp  (to see connected servers)
# Ask: "What's the monthly cost for 5 t3.large EC2 instances in us-east-1 with 100GB EBS storage?"
# Should return detailed pricing breakdown
```

### Step 9.3 Test Terraform MCP

```bash
# Inside Claude Code:
# Ask: "Show me the latest AWS provider version available in Terraform Registry"
# Should query terraform registry and return latest version
```

### Step 9.4 Test EKS MCP

```bash
# First, configure kubeconfig
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region us-east-1

# Inside Claude Code:
# Ask: "List all pods in the default namespace"
# Should show your EKS cluster info
```

### Step 9.5 Run Multi-Server Workflow

```bash
# Inside Claude Code, ask:
# "I have a Terraform project that deploys a Kubernetes app.
#  1. Analyze it for AWS costs (terraform-mcp)
#  2. Estimate monthly spend (aws-pricing)
#  3. Get EKS cluster status (eks-mcp)"
# 
# Claude should orchestrate all three servers
```

---

## Phase 10: Optimization Tips (Optional)

### Step 10.1 Switch Between Local & Cloud Models

```bash
# Quick switch to cloud model (no local resources)
ollama launch claude --model qwen3.5:cloud

# Back to local
ollama launch claude --model qwen2.5-coder:7b

# Use cloud only for complex tasks, local for rapid iteration
```

### Step 10.2 Monitor Ollama Resource Usage

```bash
# Check Ollama logs
tail -f ~/.ollama/logs/server.log

# Monitor system resources
watch -n 1 'ps aux | grep ollama'

# Check available models
ollama list
```

### Step 10.3 Optimize `MCP Server` Configuration

Create environment-specific configs:

```bash
# Development (fast, local)
cat > ~/.claude/config-dev.json << 'EOF'
{
  "model": "qwen2.5-coder:7b",
  "baseUrl": "http://localhost:11434",
  "timeout": 300
}
EOF

# Production (quality, cloud)
cat > ~/.claude/config-prod.json << 'EOF'
{
  "model": "qwen3.5:cloud",
  "baseUrl": "http://localhost:11434",
  "timeout": 600
}
EOF
```
---

## Phase 11: Verification & Testing

### Step 11.1 Start Claude Code and Check MCP Servers

```bash
# Start Claude Code with Ollama
claude

# Inside Claude Code, view all registered servers
/mcp

# Expected output:
# ✓ terraform-mcp      Connected
# ✓ aws-core-mcp       Connected
# ✓ aws-pricing-mcp    Connected
# ✓ eks-mcp            Connected
```

### Step 11.2 Test Each Server Individually

#### Test 1: Terraform Registry

```bash
# Inside Claude Code, ask:
Claude> "What versions of the AWS Terraform provider are available?"

# Claude will query terraform-mcp and return available versions
```

#### Test 2: AWS Core Operations

```bash
Claude> "Show me all my EC2 instances with their instance IDs and types"

# Claude will call aws-core-mcp and list your instances
```

#### Test 3: AWS Pricing

```bash
Claude> "What's the monthly cost for 5 m5.xlarge instances in us-east-1?"

# Claude will call aws-pricing-mcp and return pricing
```

#### Test 4: EKS Management (if you have a cluster)

```bash
Claude> "List all pods in the default namespace and their status"

# Claude will call eks-mcp and show pod details
```

### 11.3 Test Multi-Server Orchestration

Claude can use multiple MCP servers in a single request:

```bash
Claude> "I'm creating a Terraform project for an EKS cluster:
1. Find the latest AWS provider version (terraform-mcp)
2. List my current EC2 instances (aws-core-mcp)
3. Estimate monthly costs for this setup (aws-pricing-mcp)
4. Check my EKS cluster status (eks-mcp)"

# Claude orchestrates all 4 servers automatically
```

### 11.4 Create a Validation Script

```bash
#!/bin/bash
# Save as: ~/verify-mcp.sh

echo "=== MCP SERVERS VALIDATION ==="
echo ""

# Check if Claude Code is installed
if ! command -v claude &>/dev/null; then
    echo "❌ Claude Code not installed"
    exit 1
fi

echo "✅ Claude Code installed: $(claude --version)"
echo ""

# Check ~/.claude.json exists and is valid JSON
if [ ! -f ~/.claude.json ]; then
    echo "❌ ~/.claude.json not found"
    exit 1
fi

if ! python3 -m json.tool ~/.claude.json >/dev/null 2>&1; then
    echo "❌ ~/.claude.json is not valid JSON"
    exit 1
fi

echo "✅ ~/.claude.json is valid"
echo ""

# Check each MCP server is configured
for server in terraform-mcp aws-core-mcp aws-pricing-mcp eks-mcp; do
    if grep -q "\"$server\"" ~/.claude.json; then
        echo "✅ $server configured"
    else
        echo "⚠️  $server NOT configured"
    fi
done

echo ""
echo "=== MCP SERVERS CONFIGURATION ==="
echo ""

# Show mcpServers section
python3 -m json.tool ~/.claude.json | grep -A 50 '"mcpServers"' | head -60

echo ""
echo "=== CREDENTIAL CHECKS ==="
echo ""

# Check AWS credentials
if aws sts get-caller-identity >/dev/null 2>&1; then
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    echo "✅ AWS credentials configured (Account: $ACCOUNT)"
else
    echo "⚠️  AWS credentials not working - some MCP servers will fail"
fi

# Check kubeconfig for EKS
if [ -f ~/.kube/config ]; then
    echo "✅ kubeconfig found"
else
    echo "⚠️  kubeconfig not found - EKS MCP will not work"
fi

echo ""
echo "=== END VALIDATION ==="
```

Run it:
```bash
chmod +x ~/verify-mcp.sh
~/verify-mcp.sh
```

---


## Phase 12: Troubleshooting

### Issue 1: MCP Servers Not Appearing in `/mcp`

**Symptoms:** You run `/mcp` in Claude Code and see no servers listed

**Solution:**

```bash
# 1. Verify ~/.claude.json exists
ls -la ~/.claude.json

# 2. Check JSON is valid
python3 -m json.tool ~/.claude.json

# 3. Check mcpServers section exists
grep "mcpServers" ~/.claude.json

# 4. Recreate servers if corrupted
claude mcp remove terraform-mcp
claude mcp remove aws-core-mcp
claude mcp remove aws-pricing-mcp
claude mcp remove eks-mcp

# Check logs
claude mcp logs terraform-mcp
claude mcp logs aws-core-mcp

# Restart a specific MCP
claude mcp restart aws-eks-mcp

# Check uvx can resolve the package
uvx awslabs.core-mcp-server --help

# 5. Re-add all servers (see Phase 3)
```

**If still broken:**
```bash
# Backup old config
cp ~/.claude.json ~/.claude.json.bak

# Check if project-level .claude.json is overriding global
find ~ -name ".claude.json" 2>/dev/null

# If project .claude.json exists, delete it and use global
rm ./.claude.json  # (if in project directory)
```

---

### Issue 2: AWS Credentials Not Working

**Symptoms:** "AWS credentials not found" or "Access Denied"

**Solution:**

```bash
# 1. Check credentials are configured
aws configure list

# Should show:
#       Name                    Value              Type    Location
#       ----                    -----              ----    --------
#    profile                <default>           manual    --profile
# access_key     ****************XXXX        ...
# secret_key     ****************YYYY        ...
#     region                us-east-1      env,shared,config file

# 2. Test credentials work
aws sts get-caller-identity

# 3. If error, reconfigure
aws configure --profile default

# 4. Verify uvx inherits credentials
uvx aws sts get-caller-identity

# 5. Check AWS_PROFILE and AWS_REGION are set
echo $AWS_PROFILE
echo $AWS_REGION

# 6. If not set, add to ~/.bashrc
echo 'export AWS_PROFILE=default' >> ~/.bashrc
echo 'export AWS_REGION=us-east-1' >> ~/.bashrc
source ~/.bashrc
```

**Common errors:**
- "InvalidUserID.NotFound" → Access key invalid
- "SignatureDoesNotMatch" → Secret key incorrect
- "UnauthorizedOperation" → IAM permissions insufficient

---

### Issue 3: "uvx: command not found"

**Symptoms:** Error when MCP server tries to start

**Solution:**

```bash
# 1. Verify uv is installed
which uv
# Should show: /home/user/.local/bin/uv

# 2. Check PATH includes ~/.local/bin
echo $PATH | grep ".local/bin"

# 3. If not in PATH, add it
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 4. Verify uvx works
uvx --help

# 5. Test downloading a package
uvx python --version
```

---

### Issue 4: AWS Pricing API Only Works in us-east-1

**Symptoms:** "Pricing service not available in this region" error

**Solution:**

```bash
# ⚠️ IMPORTANT: aws-pricing-mcp REQUIRES us-east-1

# Check current AWS_REGION
echo $AWS_REGION

# If not us-east-1, update it
export AWS_REGION=us-east-1

# Make permanent in ~/.bashrc
echo 'export AWS_REGION=us-east-1' >> ~/.bashrc
source ~/.bashrc

# Verify MCP config has us-east-1
grep -A 5 "aws-pricing-mcp" ~/.claude.json | grep AWS_REGION
```

---

### Issue 5: EKS MCP Fails - "kubeconfig not found"

**Symptoms:** EKS commands fail with authentication errors

**Solution:**

```bash
# 1. Verify kubectl is installed
which kubectl

# 2. Configure kubeconfig for your EKS cluster
aws eks update-kubeconfig \
  --name YOUR_CLUSTER_NAME \
  --region us-east-1

# 3. Verify kubeconfig works
kubectl cluster-info

# 4. Verify it's readable
ls -la ~/.kube/config

# 5. If still failing, test uvx has access to kubeconfig
uvx kubectl cluster-info
```

---

### Issue 6: MCP Server Crashes After Starting

**Symptoms:** Server shows "Connected" briefly, then disconnects

**Check logs:**
```bash
# View recent logs
tail -f ~/.claude.log

# Check if uvx can fetch the package
uvx awslabs.core-mcp-server@latest --help

# If download fails, check internet:
ping github.com
curl -I https://pypi.org

# Try updating uv:
uv self update
```

---

### Issue 7: Permission Errors When Running Tools

**Symptoms:** "Permission denied" or "Access forbidden"

**Solution:**

```bash
# Inside Claude Code, check what permissions you've granted
/permissions

# Grant specific tool permissions
/permissions allow bash
/permissions allow file_read
/permissions allow file_write

# For development/testing ONLY (security risk):
claude --dangerously-skip-permissions

# Reset to defaults:
/permissions reset
```

---

## Advanced Configuration

### Configuration Files Explained

Claude Code uses multiple configuration layers:

```bash
# Layer 1: Global MCP servers (applies everywhere)
~/.claude.json
├── mcpServers: All 4 MCP servers

# Layer 2: Project-level overrides (only in this project)
/path/to/project/.claude.json
├── Can have different servers per project

# Layer 3: VS Code specific settings
~/.config/Code/User/settings.json
├── Claude Code extension settings
```

**Configuration precedence:**
1. Project `.claude.json` (highest priority)
2. Global `~/.claude.json`
3. VS Code `settings.json` (lowest priority)

---

### Custom MCP Server Scopes

```bash
# User scope (global, all projects)
claude mcp add my-server --scope user -- uvx my-package@latest

# Workspace scope (only current project)
claude mcp add my-server --scope workspace -- uvx my-package@latest
```

---

### Environment Variables for `MCP Server `s

Some servers need custom environment variables:

```bash
# Add with -e flag (repeatable)
claude mcp add my-server \
  -e VAR1=value1 \
  -e VAR2=value2 \
  -- uvx my-package@latest

# View env vars in config
grep -A 10 "my-server" ~/.claude.json | grep -A 3 '"env"'
```

---

### Manual Config File Editing (Advanced)

For complex setups, you can edit `~/.claude.json` directly:

```json
{
  "mcpServers": {
    "terraform-mcp": {
      "command": "uvx",
      "args": ["awslabs.terraform-mcp-server@latest"]
    },
    "aws-core-mcp": {
      "command": "uvx",
      "args": ["awslabs.core-mcp-server@latest"],
      "env": {
        "AWS_REGION": "us-east-1",
        "AWS_PROFILE": "default"
      }
    },
    "aws-pricing-mcp": {
      "command": "uvx",
      "args": ["awslabs.cost-explorer-mcp-server@latest"],
      "env": {
        "AWS_REGION": "us-east-1",
        "AWS_PROFILE": "default"
      }
    },
    "eks-mcp": {
      "command": "uvx",
      "args": ["awslabs.eks-mcp-server@latest"],
      "env": {
        "AWS_REGION": "us-east-1",
        "AWS_PROFILE": "default"
      }
    }
  }
}
```

**Validate JSON after editing:**
```bash
python3 -m json.tool ~/.claude.json
```

---

## Best Practices & Security

### 1. Credential Security

```bash
# ✅ DO: Use AWS profiles
aws configure --profile dev
aws configure --profile prod

# ✅ DO: Use environment-specific profiles in MCP config
-e AWS_PROFILE=prod

# ❌ DON'T: Store credentials in config files
# ❌ DON'T: Use root AWS access key for MCP

# ✅ DO: Use IAM users with minimal permissions
```

### 2. IAM Permissions for `MCP Servers`

**Minimum permissions needed:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "s3:ListBuckets",
        "iam:ListUsers",
        "pricing:GetProducts"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Regional Configuration

```bash
# ⚠️ CRITICAL: AWS Pricing API ONLY in us-east-1
# If your main region is different, use multiple profiles:

aws configure --profile default-us-east-1
# Set region: us-east-1

aws configure --profile prod-eu-west-1
# Set region: eu-west-1

# In MCP config:
# - For pricing: Use us-east-1 profile
# - For other operations: Use your region
```

---

## Quick Reference Commands

```bash
# View all MCP servers
cat ~/.claude.json

# Add a new server
claude mcp add <name> --scope user -- uvx <package>@latest

# Remove a server
claude mcp remove <name>

# List servers in Claude Code
/mcp

# Check server details
grep -A 5 '"<server-name>"' ~/.claude.json

# Test credentials
aws sts get-caller-identity

# Test kubectl access
kubectl cluster-info

# Test uv package manager
uvx --help

# Restart Claude Code
exit  # (exit Claude Code)
claude  # (restart)
```

---

## Performance Optimization

### First-Run Performance

First execution of each server may be slow (downloading dependencies):

```
terraform-mcp:     First run ~5-10s (downloads server)
aws-core-mcp:      First run ~8-15s (downloads + creates env)
aws-pricing-mcp:   First run ~8-15s (depends on AWS API)
eks-mcp:           First run ~8-15s (depends on kubectl)
```

Subsequent runs: **2-3 seconds** (cached)

### Optimizations

```bash
# 1. Pre-warm servers (run once after boot)
claude
/mcp
exit

# 2. Keep Ollama daemon running
sudo systemctl start ollama
sudo systemctl enable ollama

# 3. Use local models for fast iteration
ollama launch claude --model qwen2.5-coder:7b
```

---

## Testing Checklist

Before declaring setup complete:

- [ ] `claude --version` works
- [ ] `ollama serve &` runs without errors
- [ ] `uv --version` shows 0.x.x
- [ ] `aws sts get-caller-identity` returns account info
- [ ] `~/.claude.json` contains all 4 MCP servers
- [ ] `/mcp` in Claude Code shows all servers ✓ Connected
- [ ] AWS Pricing queries work with us-east-1
- [ ] EKS commands work (if you have a cluster)
- [ ] Multi-server orchestration works (ask Claude to use multiple servers)
- [ ] `validate-setup.sh` passes all checks

---

## Workflow Examples

### Example 1: Estimate Infrastructure Costs

```bash
# Inside Claude Code:
Claude> "I'm planning to launch 5 m5.xlarge EC2 instances 
         with 500GB EBS storage in us-east-1.
         What will be the monthly cost?
         Also show me how to deploy this with Terraform."

# Claude will:
# 1. Query terraform-mcp for provider syntax
# 2. Call aws-pricing-mcp for cost estimation
# 3. Generate Terraform code
```

### Example 2: Troubleshoot Kubernetes

```bash
Claude> "My EKS cluster is running but pods aren't starting.
         Show me:
         1. Pod status in all namespaces
         2. Recent errors/events
         3. Node resource usage"

# Claude will call eks-mcp to investigate
```

### Example 3: Infrastructure Review

```bash
Claude> "Review my AWS infrastructure:
         1. List all EC2 instances
         2. Check security group rules
         3. Estimate monthly costs
         4. Identify cost-saving opportunities"

# Claude orchestrates aws-core-mcp and aws-pricing-mcp
```

---

## Cleanup & Maintenance

### Remove a Single `MCP Server`

```bash
claude mcp remove terraform-mcp

# Verify removal
grep terraform-mcp ~/.claude.json  # Should not match
```

### Backup Your Configuration

```bash
cp ~/.claude.json ~/.claude.json.backup.$(date +%Y%m%d)
```

### Update All `MCP Servers`

```bash
# Reinstall with latest versions
for server in terraform-mcp aws-core-mcp aws-pricing-mcp eks-mcp; do
    claude mcp remove $server
done

# Then re-add from Phase 3
```

---

## References & Resources

| Resource | Link |
|----------|------|
| Claude Code Docs | https://docs.anthropic.com/en/docs/claude-code/overview |
| MCP Protocol Spec | https://modelcontextprotocol.io |
| AWS MCP Servers | https://github.com/awslabs/mcp |
| Ollama Integration | https://docs.ollama.com/integrations/claude-code |
| Terraform Registry API | https://www.terraform.io/cloud-docs/api-docs |
| AWS Pricing API | https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/price-endpoint.html |

---

## Appendix: Complete Setup Script

For automated setup (use with caution):

```bash
#!/bin/bash
# save as: ~/setup-mcp-complete.sh

set -e

echo "🚀 Starting complete MCP setup..."

# Phase 1: Dependencies
echo "📦 Installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git python3 python3-pip python3-venv

# Phase 2: uv
echo "⚙️  Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Phase 3: AWS CLI
echo "☁️  Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscliv2.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Phase 4: kubectl
echo "☸️  Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Phase 5: MCP Servers
echo "🔌 Adding MCP servers..."

if ! command -v claude &>/dev/null; then
    echo "❌ Claude Code not found. Install it first:"
    echo "   npm install -g @anthropic-ai/claude-code"
    exit 1
fi

claude mcp add terraform-mcp --scope user -- uvx awslabs.terraform-mcp-server@latest
claude mcp add aws-core-mcp --scope user -e AWS_REGION=us-east-1 -e AWS_PROFILE=default -- uvx awslabs.core-mcp-server@latest
claude mcp add aws-pricing-mcp --scope user -e AWS_REGION=us-east-1 -e AWS_PROFILE=default -- uvx awslabs.cost-explorer-mcp-server@latest
claude mcp add eks-mcp --scope user -e AWS_REGION=us-east-1 -e AWS_PROFILE=default -- uvx awslabs.eks-mcp-server@latest

echo "✅ MCP setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure AWS: aws configure --profile default"
echo "2. Test: claude && /mcp"
echo "3. Configure EKS kubeconfig: aws eks update-kubeconfig --name CLUSTER_NAME --region us-east-1"
```

Run it:
```bash
chmod +x ~/setup-mcp-complete.sh
~/setup-mcp-complete.sh
```

---

## Key References

- **Claude Code Docs:** https://docs.anthropic.com/en/docs/claude-code/overview
- **Ollama Docs:** https://docs.ollama.com
- **MCP Protocol:** https://modelcontextprotocol.io
- **AWS MCP Server:** https://github.com/awslabs/mcp


- Run the script after verifying everything works:
- 
```bash
chmod +x cleanup.sh
./cleanup.sh
```

```sh
 Test if your user has EC2 permissions
aws ec2 describe-instances --region us-east-1

# Test S3 permissions
aws s3 ls

# Test IAM permissions
aws iam list-users

# If any of these fail with "UnauthorizedOperation" or "AccessDenied":
# → Your IAM user lacks required permissions
```

```sh
tep-by-step guide:                                                                                                                                                                                  
                                                                                                                                                                                                     
  1. Start an MCP server                                                                                                                                                                               
                                                                                                                                                                                                       
  Use the /mcp start command followed by the server name:                                                                                                                                              
                                                                                                                                                                                                       
  /mcp start awslabs.terraform-mcp-server                                                                                                                                                              
                                                                                                                                                                                                       
  2. List running servers                                                                                                                                                                              
                                                                                                                                                                                                       
  After starting, verify with:                                                                                                                                                                         
  /mcp list                                                                                                                                                                                          
                                                                                                                                                                                                       
  3. Use MCP tools                                                                                                                                                                                     
                                                                                                                                                                                                       
  Once started, the server's tools will be available in your tool calls.                                                                                                                               
                                                                                                                                                                                                       
  ---                                                                                                                                                                                                  
  Quick commands:                                                                                                                                                                                    
                                                                                                                                                                                                       
  ┌───────────────────────┬─────────────────────────────────────────┐                                                                                                                                
  │        Command        │               Description               │                                                                                                                                  
  ├───────────────────────┼─────────────────────────────────────────┤                                                                                                                                  
  │ /mcp start <server>   │ Start a specific MCP server             │                                                                                                                                  
  ├───────────────────────┼─────────────────────────────────────────┤                                                                                                                                  
  │ /mcp stop <server>    │ Stop a running server                   │                                                                                                                                  
  ├───────────────────────┼─────────────────────────────────────────┤                                                                                                                                  
  │ /mcp list             │ List all configured and running servers │                                                                                                                                  
  ├───────────────────────┼─────────────────────────────────────────┤                                                                                                                                  
  │ /mcp restart <server> │ Restart a server                        │                                                                                                                                
  └───────────────────────┴─────────────────────────────────────────┘                                                                                                                                  
                                                                                                                                                                                                     
  ---                                                                                                                                                                                                  
  Example: Start the Terraform server                                                                                                                                                                
                                                                                                                                                                                                       
  /mcp start awslabs.terraform-mcp-server
                                                                                                                                                                                                       
  Note: The servers use uvx to run, so make sure you have uv installed. If not, install it with:                                                                                                       
  curl -LsSf https://astral.sh/uv/install.sh | sh                                                                                                                                                      
                                                                                                                                                                                                       
  Would you like me to help you start a specific MCP server now?  



I can see your MCP servers are configured in ~/.claude/settings.json. The issue is that MCP servers need to be started - they don't auto-start just by being in the config file.                     
                                                                                                                                                                                                       
  Let me verify the uvx command is available and then guide you through starting the servers:                                                                                                          
   
  Searched for 1 pattern (ctrl+o to expand)                                                                                                                                                            
                                                                                                                                                                                                     
● Good, uvx is available. Here's the step-by-step guide to start your MCP servers:                                                                                                                     
                                                                                                                                                                                                       
  Step 1: Start MCP servers using the /mcp command                                                                                                                                                     
                                                                                                                                                                                                       
  You need to start each server individually. In the Claude Code chat, type:                                                                                                                           
                                                                                                                                                                                                       
  /mcp start awslabs.core-mcp-server                                                                                                                                                                   
                                                                                                                                                                                                       
  Then repeat for each server:                                                                                                                                                                         
  /mcp start awslabs.terraform-mcp-server                                                                                                                                                              
  /mcp start awslabs.aws-pricing-mcp-server                                                                                                                                                            
  /mcp start awslabs.eks-mcp-server                                                                                                                                                                    
                                                                                                                                                                                                       
  Step 2: Verify servers are running                                                                                                                                                                   
                                                                                                                                                                                                       
  After starting, run:                                                                                                                                                                                 
  /mcp list                                                                                                                                                                                            
                                                                                                                                                                                                       
  You should see your servers listed with status "connected" or "starting".     
```

```sh
claude mcp get <servername>
```

```sh
Summary - MCP Servers Now Working                                                                                                                                                                    
                                                                                                                                                                                                       
  The Issue: Your MCP servers were configured in ~/.claude/settings.json, but Claude Code uses a project-specific config (~/.claude.json) that overrides the global settings for each project.         
   
  The Fix: I added all 4 servers to the project config using the claude mcp add command:                                                                                                               
                                                                                                                                                                                                     
  claude mcp add terraform-mcp -- uvx awslabs.terraform-mcp-server@latest                                                                                                                              
  claude mcp add aws-core-mcp -e AWS_REGION=us-east-1 -e AWS_PROFILE=default -- uvx awslabs.core-mcp-server@latest                                                                                     
  claude mcp add aws-pricing-mcp -e AWS_REGION=us-east-1 -- uvx awslabs.aws-pricing-mcp-server@latest                                                                                                  
  claude mcp add aws-eks-mcp -e AWS_REGION=us-east-1 -- uvx awslabs.eks-mcp-server@latest                                                                                                              
                                                                                                                                                                                                       
  Current Status: All 4 servers are now connected:                                                                                                                                                     
  - terraform-mcp ✓                                                                                                                                                                                    
  - aws-core-mcp ✓                                                                                                                                                                                     
  - aws-pricing-mcp ✓                                                                                                                                                                                
  - aws-eks-mcp ✓                                                                                                                                                                                      
                                                                                                                                                                                                       
  Key Takeaway: MCP servers must be added using the claude mcp add command (which writes to ~/.claude.json), not just by editing ~/.claude/settings.json manually. The settings.json file is for global
   Claude Code settings, while MCP server configs live in the project-specific ~/.claude.json.                                                                                        
                                                                                                 
```

```sh
claude skills install terraform-skill                                                                                                                                                                

● I don't have a built-in skill for installing other skills. The skills I listed are the ones that come pre-configured with Claude Code.

  To add custom skills, you would need to:

  1. Create a skill file in ~/.claude/skills/ directory (or project-level .claude/skills/)
  2. Define the skill with a name, description, and the prompt/instructions it should execute

  For a Terraform skill, you could create a file like ~/.claude/skills/terraform.md:

  # terraform

  Help the user with Terraform infrastructure tasks including:
  - Writing and validating Terraform configurations
  - Planning and applying infrastructure changes
  - Troubleshooting Terraform errors
  - Following security best practices for AWS resources

  Would you like me to:
  1. Create a Terraform skill file for you in ~/.claude/skills/?
  2. Check if there's an existing skill marketplace or repository you're referencing?                                                                                                                  
                                                                                     
  Let me know which approach you'd prefer.                                  
```

# My Custom terraform skills
```sh
# terraform

Help the user with Terraform infrastructure tasks.

## Capabilities

- Write and validate Terraform configurations for AWS
- Plan and apply infrastructure changes safely
- Troubleshoot Terraform errors and state issues
- Follow security best practices for AWS resources
- Use Terraform modules (especially AWS-IA modules)
- Manage Terraform state and backends
- Implement CI/CD for Terraform workflows

## Workflow

1. **Check for existing AWS-IA modules** before writing custom resources
2. **Validate configurations** with `terraform validate` before applying
3. **Always run `terraform plan`** before `terraform apply`
4. **Scan for security issues** using tools like checkov when appropriate
5. **Use remote state** with proper locking for team environments

## Best Practices

- Use specific resource permissions (least privilege)
- Enable encryption for state backends
- Tag all resources consistently
- Use variables for environment-specific values
- Implement proper dependency management
- Document inputs and outputs for modules
```

Note: docker-compose also need to install and start
