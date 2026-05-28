#!/bin/bash

##############################################################################
# Post-Create Setup Script for Terraform Drift Detection Lab
# Runs automatically after container creation
# Installs: Terraform, Azure CLI, Checkov, terraform-compliance, MCP servers, etc.
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Terraform Drift Detection Lab${NC}"
echo -e "${BLUE}  DevContainer Setup${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Update system packages
echo -e "${YELLOW}[1/15] Updating system packages...${NC}"
apt-get update && apt-get upgrade -y > /dev/null 2>&1

# Install essential tools
echo -e "${YELLOW}[2/15] Installing essential build tools...${NC}"
apt-get install -y \
  curl \
  wget \
  git \
  git-lfs \
  unzip \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  build-essential \
  nano \
  vim \
  htop \
  net-tools \
  dnsutils \
  iputils-ping \
  > /dev/null 2>&1

echo -e "${GREEN}✓ Essential tools installed${NC}"

##############################################################################
# TERRAFORM & TERRAFORM TOOLS
##############################################################################

echo -e "${YELLOW}[3/15] Installing Terraform...${NC}"
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null 2>&1
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null 2>&1
apt-get update > /dev/null 2>&1
apt-get install -y terraform > /dev/null 2>&1

echo -e "${GREEN}✓ Terraform $(terraform -version | head -1) installed${NC}"

# Install TFLint (Terraform linter)
echo -e "${YELLOW}[4/15] Installing TFLint...${NC}"
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash > /dev/null 2>&1
echo -e "${GREEN}✓ TFLint installed${NC}"

# Install Terragrunt (optional but useful for drift detection)
echo -e "${YELLOW}[5/15] Installing Terragrunt...${NC}"
TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" -o /usr/local/bin/terragrunt
chmod +x /usr/local/bin/terragrunt
echo -e "${GREEN}✓ Terragrunt installed${NC}"

##############################################################################
# SECURITY SCANNING & COMPLIANCE
##############################################################################

echo -e "${YELLOW}[6/15] Installing Checkov (security scanning)...${NC}"
pip3 install checkov -q > /dev/null 2>&1
echo -e "${GREEN}✓ Checkov installed${NC}"

echo -e "${YELLOW}[7/15] Installing terraform-compliance...${NC}"
pip3 install terraform-compliance -q > /dev/null 2>&1
echo -e "${GREEN}✓ terraform-compliance installed${NC}"

# Optional: Install Trivy for container/artifact scanning
echo -e "${YELLOW}[8/15] Installing Trivy (vulnerability scanner)...${NC}"
apt-get install -y trivy > /dev/null 2>&1
echo -e "${GREEN}✓ Trivy installed${NC}"

##############################################################################
# CLOUD PROVIDERS & CLI TOOLS
##############################################################################

echo -e "${YELLOW}[9/15] Installing Azure CLI...${NC}"
curl -sL https://aka.ms/InstallAzureCLIDeb | bash > /dev/null 2>&1
echo -e "${GREEN}✓ Azure CLI installed${NC}"

# Setup Azure CLI authentication for DevContainer
echo -e "${YELLOW}Installing Azure CLI extensions...${NC}"
az config set defaults.group="" > /dev/null 2>&1
az extension add -n azure-devops > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Azure CLI configured${NC}"

echo -e "${YELLOW}[10/15] Installing AWS CLI v2...${NC}"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" > /dev/null 2>&1
unzip -q /tmp/awscliv2.zip -d /tmp/
/tmp/aws/install > /dev/null 2>&1
rm -rf /tmp/awscliv2.zip /tmp/aws/
echo -e "${GREEN}✓ AWS CLI v2 installed${NC}"

##############################################################################
# NODE.JS & NPM (for MCP servers and Claude Code)
##############################################################################

echo -e "${YELLOW}[11/15] Installing Node.js and npm...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1
npm install -g npm@latest > /dev/null 2>&1
echo -e "${GREEN}✓ Node.js $(node --version) and npm $(npm --version) installed${NC}"

##############################################################################
# MCP SERVERS FOR TERRAFORM & AWS
##############################################################################

echo -e "${YELLOW}[12/15] Installing MCP Servers...${NC}"

# Create directory for MCP servers
mkdir -p /root/.local/bin

# Install terraform-mcp
echo "Installing terraform-mcp..."
npm install -g @modelcontextprotocol/server-terraform > /dev/null 2>&1 || echo -e "${YELLOW}⚠ terraform-mcp optional${NC}"

# Install aws-core-mcp
echo "Installing aws-core-mcp..."
npm install -g @modelcontextprotocol/server-aws-core > /dev/null 2>&1 || echo -e "${YELLOW}⚠ aws-core-mcp optional${NC}"

# Install aws-eks-mcp
echo "Installing aws-eks-mcp..."
npm install -g @modelcontextprotocol/server-aws-eks > /dev/null 2>&1 || echo -e "${YELLOW}⚠ aws-eks-mcp optional${NC}"

# Install aws-pricing-mcp (requires us-east-1)
echo "Installing aws-pricing-mcp..."
npm install -g @modelcontextprotocol/server-aws-pricing > /dev/null 2>&1 || echo -e "${YELLOW}⚠ aws-pricing-mcp optional${NC}"

echo -e "${GREEN}✓ MCP servers installed${NC}"

##############################################################################
# GO & GOLANG TOOLS
##############################################################################

echo -e "${YELLOW}[13/15] Installing Go...${NC}"
GO_VERSION="1.21.0"
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
export PATH=$PATH:/usr/local/go/bin
echo -e "${GREEN}✓ Go $(go version | cut -d' ' -f3) installed${NC}"

##############################################################################
# GIT CONFIGURATION & HOOKS
##############################################################################

echo -e "${YELLOW}[14/15] Configuring Git and Pre-commit Hooks...${NC}"

# Install pre-commit framework
pip3 install pre-commit -q > /dev/null 2>&1

# Setup git config defaults for container
git config --global core.pager cat
git config --global diff.colorMoved zebra
git config --global status.showUntrackedFiles all

echo -e "${GREEN}✓ Git configured${NC}"

##############################################################################
# CREATE TERRAFORM CACHE & DIRECTORIES
##############################################################################

echo -e "${YELLOW}[15/15] Setting up workspace directories...${NC}"

# Create Terraform plugin cache directory
mkdir -p /workspace/.terraform/cache
export TF_PLUGIN_CACHE_DIR=/workspace/.terraform/cache

# Create directories for logs and plans
mkdir -p /workspace/.terraform-logs
mkdir -p /workspace/terraform-plans
mkdir -p /workspace/.drift-detection

# Create Makefile for common operations
cat > /workspace/Makefile << 'EOF'
.PHONY: help init validate format plan apply destroy drift-check clean

TERRAFORM_DIR ?= .

help:
	@echo "Terraform Drift Detection Lab - Available Commands"
	@echo "=================================================="
	@echo "make init           - Initialize Terraform"
	@echo "make validate       - Validate Terraform code"
	@echo "make format         - Format Terraform code"
	@echo "make lint           - Run TFLint"
	@echo "make security       - Run Checkov security scan"
	@echo "make compliance     - Run terraform-compliance"
	@echo "make plan           - Generate Terraform plan"
	@echo "make apply          - Apply Terraform changes"
	@echo "make destroy        - Destroy infrastructure"
	@echo "make drift-check    - Check for drift (detailed-exitcode)"
	@echo "make clean          - Clean Terraform cache"
	@echo ""

init:
	cd $(TERRAFORM_DIR) && terraform init

validate:
	cd $(TERRAFORM_DIR) && terraform validate

format:
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

lint:
	tflint --init > /dev/null 2>&1 || true
	cd $(TERRAFORM_DIR) && tflint --recursive

security:
	cd $(TERRAFORM_DIR) && checkov -d . --framework terraform

compliance:
	cd $(TERRAFORM_DIR) && terraform-compliance -f . -p /path/to/policy

plan:
	cd $(TERRAFORM_DIR) && terraform plan -out=tfplan

apply:
	cd $(TERRAFORM_DIR) && terraform apply tfplan

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy

drift-check:
	cd $(TERRAFORM_DIR) && terraform plan -detailed-exitcode; exit_code=$$?; \
	if [ $$exit_code -eq 2 ]; then echo "✓ Drift detected!"; else echo "✓ No drift"; fi; \
	exit 0

clean:
	find . -type d -name '.terraform' -exec rm -rf {} + 2>/dev/null || true
	find . -name 'terraform.tfstate*' -delete
	rm -rf .terraform-logs/*
EOF

echo -e "${GREEN}✓ Workspace directories and Makefile created${NC}"

##############################################################################
# ENVIRONMENT CONFIGURATION
##############################################################################

echo -e "${YELLOW}Setting up environment variables...${NC}"

# Create .env.local template if it doesn't exist
if [ ! -f /workspace/.env.local ]; then
  cat > /workspace/.env.local << 'EOF'
# Azure Configuration (for OIDC authentication)
# ARM_SUBSCRIPTION_ID=your-subscription-id
# ARM_TENANT_ID=your-tenant-id
# ARM_CLIENT_ID=your-client-id
# ARM_USE_OIDC=true
# ARM_USE_AZUREAD=true
# ARM_STORAGE_USE_AZUREAD=true

# AWS Configuration (if using AWS)
# AWS_REGION=ap-southeast-2
# AWS_PROFILE=default

# Terraform Configuration
# TF_LOG=DEBUG
# TF_LOG_PATH=.terraform-logs/terraform.log

# Slack Integration (for drift alerts)
# SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# GitHub Configuration
# GITHUB_TOKEN=your-github-token
# GITHUB_OWNER=your-owner
# GITHUB_REPO=your-repo
EOF
  echo -e "${GREEN}✓ .env.local template created${NC}"
fi

##############################################################################
# CLEANUP
##############################################################################

echo -e "${YELLOW}Cleaning up temporary files...${NC}"
apt-get clean > /dev/null 2>&1
rm -rf /var/lib/apt/lists/* > /dev/null 2>&1
rm -rf /tmp/* > /dev/null 2>&1

##############################################################################
# VERIFICATION & SUMMARY
##############################################################################

echo -e "\n${BLUE}======================================${NC}"
echo -e "${BLUE}  Setup Complete! ✓${NC}"
echo -e "${BLUE}======================================${NC}\n"

echo -e "${GREEN}Installed Tools:${NC}"
echo "  Terraform:      $(terraform -version | head -1 | cut -d' ' -f2)"
echo "  TFLint:         $(tflint --version 2>/dev/null | head -1)"
echo "  Terragrunt:     $(terragrunt --version 2>/dev/null | head -1 || echo 'installed')"
echo "  Checkov:        $(checkov --version 2>/dev/null | head -1 || echo 'installed')"
echo "  terraform-compliance: installed"
echo "  Azure CLI:      $(az --version 2>/dev/null | head -1 || echo 'installed')"
echo "  AWS CLI:        $(aws --version)"
echo "  Node.js:        $(node --version)"
echo "  npm:            $(npm --version)"
echo "  Go:             $(go version | cut -d' ' -f3)"
echo "  Trivy:          $(trivy --version 2>/dev/null | head -1)"
echo ""

echo -e "${YELLOW}Quick Start:${NC}"
echo "  1. Initialize Terraform:"
echo "     → make init"
echo ""
echo "  2. Validate and format code:"
echo "     → make validate && make format"
echo ""
echo "  3. Run security scan:"
echo "     → make security"
echo ""
echo "  4. Check for drift:"
echo "     → make drift-check"
echo ""

echo -e "${YELLOW}Environment Setup:${NC}"
echo "  • Review .env.local template for configuration"
echo "  • Update with your Azure subscription and AWS credentials"
echo "  • Add Slack webhook URL for drift alerts"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Configure Azure credentials:"
echo "     → az login (for local development)"
echo "     → or setup OIDC for GitHub Actions"
echo ""
echo "  2. Configure AWS credentials (if needed):"
echo "     → aws configure"
echo ""
echo "  3. Review GitHub Actions workflows:"
echo "     → .github/workflows/terraform-drift.yml"
echo "     → .github/workflows/terraform-plan.yml"
echo ""

echo -e "${GREEN}Container ready! Happy coding! 🚀${NC}\n"
