# DevContainer Setup Guide - Terraform Drift Detection Lab

## Overview

This DevContainer provides a complete, production-ready development environment for the **Terraform Drift Detection** project with:

- ✅ **Terraform & Tools**: Terraform, TFLint, Terragrunt
- ✅ **Security Scanning**: Checkov, terraform-compliance, Trivy
- ✅ **Cloud Tools**: Azure CLI, AWS CLI, kubectl
- ✅ **MCP Servers**: terraform-mcp, aws-core-mcp, aws-eks-mcp, aws-pricing-mcp
- ✅ **Programming Languages**: Node.js, Go, Python
- ✅ **Development Tools**: Git, pre-commit, Docker-in-Docker
- ✅ **IDE Extensions**: Terraform, Azure, GitHub, Live Share, Copilot

No installation required locally—everything runs in the container!

---

## Quick Start (5 Minutes)

### Prerequisites
- **VSCode** installed
- **Docker Desktop** or Docker Engine running
- **Dev Containers extension** installed in VSCode

### Step 1: Copy DevContainer Files

Copy these 4 files to your project root:

```bash
# Create the .devcontainer directory
mkdir -p .devcontainer

# Copy the provided files:
# - devcontainer.json  (main configuration)
# - post-create.sh     (setup script)
# - post-start.sh      (startup health checks)
# - Dockerfile         (optional custom base image)
# - .env.example       (environment template)
```

**File structure:**
```
your-terraform-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── post-create.sh
│   ├── post-start.sh
│   └── Dockerfile (optional)
├── .github/
│   └── workflows/
│       └── terraform-drift.yml
└── ... (your terraform code)
```

### Step 2: Open in DevContainer

1. **Open your Terraform project in VSCode**
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Type: **"Dev Containers: Reopen in Container"**
4. Wait 2-5 minutes for setup to complete (first run is slower)
5. Check bottom-left corner for `[Dev Container]` indicator

### Step 3: Verify Installation

Open VSCode terminal (`Ctrl+backtick`) and run:

```bash
# Test all tools
terraform -version
tflint --version
checkov --version
az --version
aws --version
node --version
npm --version
```

All commands should work without errors!

### Step 4: Configure Environment (First Run Only)

Copy the environment template and update with your credentials:

```bash
# Copy example to local config
cp .devcontainer/.env.example .env.local

# Edit with your values
nano .env.local

# Key values to set:
# - AZURE_SUBSCRIPTION_ID
# - AZURE_TENANT_ID
# - AZURE_CLIENT_ID
# - STORAGE_ACCOUNT_NAME
# - AWS_REGION (optional)
# - SLACK_WEBHOOK_URL (optional)
```

**Note**: `.env.local` is gitignored and won't be committed.

---

## File Descriptions

### `devcontainer.json` (Main Configuration)

**What it does:**
- Defines the container base image (Ubuntu 22.04)
- Specifies VSCode extensions to install
- Configures environment variables
- Mounts local directories (.ssh, .azure, .aws)
- Sets up port forwarding
- Runs post-create and post-start scripts

**Key sections:**
```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-22.04",
  "features": { /* Docker, GitHub CLI */ },
  "customizations": { /* VSCode extensions and settings */ },
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "remoteEnv": { /* Environment variables */ }
}
```

### `post-create.sh` (One-Time Setup)

**What it does** (runs once when container is created):
- Updates system packages
- Installs Terraform, TFLint, Terragrunt
- Installs Checkov, terraform-compliance, Trivy
- Installs Azure CLI, AWS CLI
- Installs Node.js and MCP servers
- Installs Go for MCP development
- Creates Makefile with common tasks
- Creates `.env.local` template

**Execution time**: 3-5 minutes (first run)

### `post-start.sh` (Every Container Start)

**What it does** (runs every time container starts):
- Loads `.env.local` environment variables
- Performs health checks on tools
- Initializes Terraform if needed
- Checks Azure authentication
- Checks AWS configuration
- Displays ready status

**Execution time**: ~10 seconds

### `Dockerfile` (Optional Custom Image)

**When to use:**
- If you want full control over the base image
- To pre-install additional tools
- For custom health checks

**To use it:**
Change in `devcontainer.json`:
```json
// Instead of:
"image": "mcr.microsoft.com/devcontainers/base:ubuntu-22.04",

// Use:
"dockerFile": ".devcontainer/Dockerfile"
```

### `.env.example` (Environment Template)

**What to configure:**
- Azure Subscription ID
- Azure Tenant ID
- Azure Client ID (Service Principal)
- AWS Region
- GitHub Token
- Slack Webhook URL
- Terraform settings

---

## Configuration Guide

### Azure OIDC Setup (For Your Drift Detection)

The DevContainer supports Azure OIDC authentication for GitHub Actions:

**1. Create Service Principal (if not exists):**
```bash
# Inside or outside container
az ad sp create-for-rbac --name "demo-github-azure-oidc-connection" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

**2. Set in `.env.local`:**
```bash
AZURE_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
AZURE_TENANT_ID=00000000-0000-0000-0000-000000000000
AZURE_CLIENT_ID=00000000-0000-0000-0000-000000000000
ARM_USE_OIDC=true
ARM_USE_AZUREAD=true
```

**3. For local development in container:**
```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

### Azure Blob Storage Backend

**1. Create storage account:**
```bash
# Inside container
az storage account create \
  --name mystorageaccount \
  --resource-group my-terraform-backend-rg \
  --location eastus

az storage container create \
  --name tfstate \
  --account-name mystorageaccount
```

**2. Set in `.env.local`:**
```bash
STORAGE_ACCOUNT_NAME=mystorageaccount
BACKEND_RESOURCE_GROUP=my-terraform-backend-rg
BACKEND_STORAGE_CONTAINER=tfstate
```

**3. Create `backend-azure.hcl`:**
```hcl
resource_group_name  = "my-terraform-backend-rg"
storage_account_name = "mystorageaccount"
container_name       = "tfstate"
key                  = "terraform.tfstate"
```

### AWS Configuration (Optional)

**For local development:**
```bash
# Inside container
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

**For AWS MCP servers:**
```bash
# Set in .env.local
AWS_REGION=ap-southeast-2
AWS_ACCOUNT_ID=123456789012
```

### Slack Integration (For Drift Alerts)

**1. Create Incoming Webhook:**
- Go to Slack App → Incoming Webhooks
- Click "Create New Webhook"
- Select channel: `#terraform-drift-alerts`
- Copy webhook URL

**2. Set in `.env.local`:**
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXX
```

**3. Use in GitHub Actions:**
```yaml
- name: Send Slack notification
  if: steps.plan.outputs.exitcode == 2  # Drift detected
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "🚨 Terraform Drift Detected",
        "blocks": [
          { "type": "section", "text": { "type": "mrkdwn", "text": "Drift found in ${{ github.repository }}" } }
        ]
      }
```

---

## Common Tasks

### Initialize Terraform

```bash
# Inside container terminal
terraform init -backend-config=backend-azure.hcl

# Or using Makefile
make init
```

### Validate & Format Code

```bash
# Validate
terraform validate

# Format
terraform fmt -recursive

# Or:
make validate && make format
```

### Run Security Scans

```bash
# Checkov
checkov -d . --framework terraform

# terraform-compliance
terraform-compliance -f . -p policies/

# Both:
make security
```

### Check for Drift

```bash
# Manual drift check (like your GitHub Actions)
terraform plan -detailed-exitcode
# Exit code 2 = drift detected

# Or using Makefile
make drift-check
```

### Apply Changes

```bash
terraform plan -out=tfplan
terraform apply tfplan

# Or using Makefile
make plan && make apply
```

### Destroy Infrastructure

```bash
terraform destroy

# Or:
make destroy
```

---

## IDE Extensions in Container

The following VSCode extensions are automatically installed:

| Extension | Purpose |
|-----------|---------|
| `hashicorp.terraform` | Terraform syntax, formatting, validation |
| `ms-azuretools.vscode-azureterraform` | Azure Terraform support |
| `ms-azuretools.vscode-docker` | Docker management |
| `ms-vscode.azure-account` | Azure account management |
| `ms-vsliveshare.vsliveshare` | Real-time code collaboration |
| `github.copilot` | AI-assisted coding |
| `eamodio.gitlens` | Git visualization and blame |
| `ms-python.python` | Python support (for scripts) |

**Access extensions inside container:**
Press `Ctrl+Shift+X` to open Extensions marketplace—all are pre-installed!

---

## Live Share for Team Collaboration

### Host (Share Your Code)

1. **Start Live Share session:**
   - `Ctrl+Shift+P` → "Live Share: Start collaboration session"
   - Or click "Live Share" button in status bar

2. **Copy invitation link:**
   - Automatically copied to clipboard
   - Or click "Copy Invitation Link"

3. **Share with colleague:**
   - Send the link via Slack, email, etc.
   - Only share with trusted team members

### Guest (Join Session)

1. **Receive invitation link** from host
2. **Click the link** in browser or VSCode
3. **VSCode opens** and connects to host's container
4. **Start collaborating:**
   - Edit code together in real-time
   - Run terminal commands together
   - See each other's cursors

### Live Share + DevContainer Benefits

- Guest doesn't need Docker, Terraform, or anything installed locally
- Guest automatically gets access to all container tools
- Perfect for:
  - **Pair programming** on drift detection workflows
  - **Code reviews** of Terraform changes
  - **Live debugging** of infrastructure issues
  - **Mentoring** junior engineers

---

## Troubleshooting

### Problem: "Docker daemon not running"

**Solution:**
```bash
# Start Docker Desktop on Windows/Mac
# Or on Linux:
sudo systemctl start docker
```

### Problem: "Permission denied" errors

**Solution:**
```bash
# Add current user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run VSCode as root (not recommended)
```

### Problem: Container takes too long to build

**Solution:**
```bash
# Rebuild from scratch (clears cache)
Ctrl+Shift+P → "Dev Containers: Rebuild Container"

# This is normal for first-time builds (3-5 minutes)
# Subsequent builds are faster
```

### Problem: "Terraform init fails"

**Solution:**
```bash
# Make sure backend configuration is set
terraform init -backend-config=backend-azure.hcl

# Or use interactive mode (not recommended for CI/CD)
terraform init
```

### Problem: Azure CLI not authenticated

**Solution:**
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <SUBSCRIPTION_ID>

# Verify
az account show
```

### Problem: MCP servers not accessible

**Solution:**
1. Check Node.js installation:
   ```bash
   npm list -g @modelcontextprotocol/server-terraform
   ```

2. Reinstall if needed:
   ```bash
   npm install -g @modelcontextprotocol/server-terraform
   ```

3. Verify Claude Code can find them:
   ```bash
   which terraform-mcp
   ```

---

## Best Practices

### ✅ Do's

1. **Commit `.devcontainer` folder** to git so team uses same environment
2. **Update `.env.example`** when adding new environment variables
3. **Keep `.env.local` in `.gitignore`** (never commit credentials)
4. **Test DevContainer** on fresh clone before shipping
5. **Document any custom setup** in this README
6. **Use Makefile** for common tasks (easier for team)
7. **Version your tools** in `post-create.sh` (pin specific versions)

### ❌ Don'ts

1. **Don't store credentials** in DevContainer or `.env` files
2. **Don't commit `.env.local`** to git
3. **Don't use root user** for everything (use remoteUser)
4. **Don't make container too large** (slim down what you install)
5. **Don't ignore security warnings** from Checkov
6. **Don't modify post-create.sh** during development (rebuild on change)

---

## For Your Drift Detection Project

### Your Specific Setup

This DevContainer is pre-configured for your exact workflow:

1. **Azure OIDC** for GitHub Actions authentication
2. **Blob Storage** remote backend (Checkov-compliant)
3. **GitHub Actions** drift detection workflows
4. **Slack** integration for drift alerts
5. **Multiple MCP servers** for Claude Code integration
6. **Makefile** with drift-check task

### Recommended Flow

```bash
# 1. Setup (first time only)
cp .devcontainer/.env.example .env.local
# Edit .env.local with your values

# 2. Daily development
terraform validate
terraform fmt -recursive
checkov -d . --framework terraform
terraform plan -out=tfplan

# 3. Check for drift (before merge)
make drift-check

# 4. Collaborate with team
# Start Live Share session for pair review of drift detection logic
Ctrl+Shift+P → "Live Share: Start collaboration session"

# 5. Push and watch GitHub Actions
# GitHub Actions will run your drift detection workflow
```

---

## Getting Help

### Documentation References

- **Terraform**: https://www.terraform.io/docs
- **Azure CLI**: https://learn.microsoft.com/en-us/cli/azure/
- **Checkov**: https://www.checkov.io/
- **terraform-compliance**: https://terraform-compliance.com/
- **Dev Containers**: https://code.visualstudio.com/docs/devcontainers/containers
- **Live Share**: https://code.visualstudio.com/docs/remote/liveshare

### Common Issues

- **Terraform state issues**: Check `terraform.tfstate` file permissions in Azure
- **Checkov failures**: Review security findings at https://www.checkov.io/
- **Azure auth issues**: Ensure Service Principal has correct RBAC roles
- **Slack webhook issues**: Verify URL is correct and channel exists

---

## Advanced: Customization

### Add Custom Tools

Edit `.devcontainer/post-create.sh`:

```bash
# Add near the end, before "Setup Complete"
echo "Installing custom tool..."
apt-get install -y my-custom-tool
```

Then rebuild: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

### Use Different Base Image

Edit `devcontainer.json`:

```json
"image": "mcr.microsoft.com/devcontainers/typescript-node:0-20"
```

### Pre-load Terraform Providers

Create `.devcontainer/providers.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

Then in `post-create.sh`:
```bash
terraform -chdir=.devcontainer init
```

---

## Summary

You now have a **production-ready DevContainer** for Terraform Drift Detection with:

- ✅ All tools pre-installed
- ✅ Azure OIDC configured
- ✅ Security scanning enabled
- ✅ MCP servers ready
- ✅ Team collaboration (Live Share)
- ✅ GitHub Actions integration
- ✅ Slack notifications

**Next steps:**
1. Copy the 5 files to `.devcontainer/`
2. `Reopen in Container`
3. Create `.env.local` from template
4. Run `terraform init`
5. Start coding! 🚀

---

**Questions?** Check the troubleshooting section or refer to official documentation links above.

Happy coding! 🎉
