#!/bin/bash

##############################################################################
# Post-Start Setup Script for Terraform Drift Detection Lab
# Runs every time the container starts (but not on creation)
# Sets up environment and performs health checks
##############################################################################

set -e

# Colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}[Container Start] Performing health checks and environment setup...${NC}"

# Load environment variables if .env.local exists
if [ -f /workspace/.env.local ]; then
  set -a
  source /workspace/.env.local
  set +a
  echo -e "${GREEN}✓ Environment variables loaded from .env.local${NC}"
fi

# Verify Terraform state directory exists
mkdir -p /workspace/.terraform/cache
mkdir -p /workspace/.terraform-logs
mkdir -p /workspace/terraform-plans

# Setup Terraform plugin cache
export TF_PLUGIN_CACHE_DIR=/workspace/.terraform/cache

# Verify essential tools are available
echo -e "${YELLOW}Verifying tools...${NC}"

for cmd in terraform tflint checkov az aws node npm; do
  if command -v $cmd &> /dev/null; then
    echo -e "${GREEN}✓ $cmd${NC}"
  else
    echo -e "${YELLOW}⚠ $cmd not found${NC}"
  fi
done

# Initialize Terraform if not already done
if [ ! -d "/workspace/.terraform" ]; then
  echo -e "${YELLOW}First run detected. Initializing Terraform...${NC}"
  cd /workspace 2>/dev/null || true
  terraform init || echo -e "${YELLOW}⚠ Terraform init requires backend configuration${NC}"
fi

# Check Azure CLI login status
if [ -n "$ARM_CLIENT_ID" ] || [ -n "$AZURE_SUBSCRIPTION_ID" ]; then
  echo -e "${YELLOW}Checking Azure authentication...${NC}"
  if az account show &> /dev/null; then
    AZURE_ACCOUNT=$(az account show --query user.name -o tsv 2>/dev/null)
    echo -e "${GREEN}✓ Azure authenticated as: $AZURE_ACCOUNT${NC}"
  else
    echo -e "${YELLOW}⚠ Azure not authenticated. Run: az login${NC}"
  fi
fi

# Check AWS CLI configuration
if [ -n "$AWS_REGION" ]; then
  echo -e "${YELLOW}Checking AWS configuration...${NC}"
  if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account -o text 2>/dev/null)
    echo -e "${GREEN}✓ AWS configured for account: $AWS_ACCOUNT${NC}"
  else
    echo -e "${YELLOW}⚠ AWS not configured. Run: aws configure${NC}"
  fi
fi

echo -e "${GREEN}✓ Container ready!${NC}\n"
