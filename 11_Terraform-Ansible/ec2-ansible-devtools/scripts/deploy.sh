#!/usr/bin/env bash
###############################################################################
# deploy.sh — Full automation: Terraform + Ansible
#
# Usage:
#   chmod +x scripts/deploy.sh
#   ./scripts/deploy.sh
#
# Prerequisites:
#   - AWS CLI configured (aws configure OR env vars)
#   - Terraform >= 1.5 installed
#   - Ansible >= 2.14 installed
#   - Python packages: boto3 botocore
#   - Ansible collection: amazon.aws
###############################################################################

set -euo pipefail

# ─── Colours ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

# ─── Config ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform"
ANSIBLE_DIR="${ROOT_DIR}/ansible"
PROJECT_NAME="devtools-lab"
MAX_WAIT_SECONDS=180    # Max time to wait for EC2 to be SSH-ready

# ─── Helpers ─────────────────────────────────────────────────────────────────
log()     { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${NC}"; \
            echo -e "${BOLD}${CYAN}  $*${NC}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${NC}\n"; }

# ─── Preflight checks ────────────────────────────────────────────────────────
header "Step 0 — Preflight Checks"

command -v terraform >/dev/null 2>&1  || error "terraform not found. Install from https://developer.hashicorp.com/terraform/downloads"
command -v ansible   >/dev/null 2>&1  || error "ansible not found.   Run: pip install ansible"
command -v aws       >/dev/null 2>&1  || error "aws-cli not found.   Run: pip install awscli"
command -v python3   >/dev/null 2>&1  || error "python3 not found."

log "Checking Python dependencies (boto3, botocore)..."
python3 -c "import boto3, botocore" 2>/dev/null || {
  warn "boto3/botocore not found — installing..."
  pip3 install boto3 botocore --quiet
}

log "Checking Ansible collection: amazon.aws ..."
ansible-galaxy collection list 2>/dev/null | grep -q "amazon.aws" || {
  warn "amazon.aws collection not found — installing..."
  ansible-galaxy collection install amazon.aws --quiet
}

log "Verifying AWS credentials..."
aws sts get-caller-identity --output table || error "AWS credentials not configured. Run: aws configure"

success "All preflight checks passed."

# ─── Step 1: Terraform ───────────────────────────────────────────────────────
header "Step 1 — Terraform: Provision EC2"

cd "${TERRAFORM_DIR}"

# Copy tfvars example if tfvars not present
if [[ ! -f "terraform.tfvars" ]]; then
  warn "terraform.tfvars not found — copying from example..."
  cp terraform.tfvars.example terraform.tfvars
  warn "Review and edit terraform/terraform.tfvars if needed, then re-run this script."
fi

log "Running terraform init..."
terraform init -upgrade

log "Running terraform plan..."
terraform plan -out=tfplan

log "Running terraform apply..."
terraform apply -auto-approve tfplan

# Capture outputs
INSTANCE_IP=$(terraform output -raw instance_public_ip)
INSTANCE_ID=$(terraform output -raw instance_id)
SSH_COMMAND=$(terraform output -raw ssh_command)
KEY_PATH="${ANSIBLE_DIR}/${PROJECT_NAME}-key.pem"

success "EC2 instance provisioned!"
log "  Instance ID : ${INSTANCE_ID}"
log "  Public IP   : ${INSTANCE_IP}"
log "  Key path    : ${KEY_PATH}"

# ─── Step 2: Wait for SSH ────────────────────────────────────────────────────
header "Step 2 — Wait for EC2 SSH Readiness"

log "Waiting for SSH on ${INSTANCE_IP}:22 (timeout: ${MAX_WAIT_SECONDS}s)..."
WAITED=0
until ssh -i "${KEY_PATH}" \
          -o StrictHostKeyChecking=no \
          -o ConnectTimeout=5 \
          -o BatchMode=yes \
          ubuntu@"${INSTANCE_IP}" "echo ready" 2>/dev/null; do
  if [[ $WAITED -ge $MAX_WAIT_SECONDS ]]; then
    error "Timed out waiting for SSH on ${INSTANCE_IP}"
  fi
  echo -n "."
  sleep 5
  WAITED=$((WAITED + 5))
done
echo ""
success "SSH is ready on ${INSTANCE_IP} (waited ${WAITED}s)"

# ─── Step 3: Ansible ─────────────────────────────────────────────────────────
header "Step 3 — Ansible: Install Packages"

cd "${ANSIBLE_DIR}"

# Update the project name in inventory if different from default
sed -i "s/devtools-lab/${PROJECT_NAME}/g" \
    inventory/aws_ec2.yml 2>/dev/null || true

log "Testing Ansible connectivity with dynamic inventory..."
ansible all -i inventory/aws_ec2.yml -m ping \
    --private-key="${KEY_PATH}" \
    -u ubuntu \
    -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" || {
  warn "Dynamic inventory ping failed — falling back to static inventory..."
  ansible all -i inventory/static_hosts.ini -m ping || \
      error "Both inventories failed. Check your instance and SSH key."
}

log "Running installation playbook..."
ansible-playbook playbooks/install_packages.yml \
    -i inventory/aws_ec2.yml \
    --private-key="${KEY_PATH}" \
    -u ubuntu \
    -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
    -v

# ─── Step 4: Summary ─────────────────────────────────────────────────────────
header "Deployment Complete ✓"

echo -e "${GREEN}${BOLD}"
echo "  ┌────────────────────────────────────────────────────┐"
echo "  │           EC2 + DevTools Ready!                   │"
echo "  ├────────────────────────────────────────────────────┤"
echo "  │ Instance ID : ${INSTANCE_ID}                        "
echo "  │ Public IP   : ${INSTANCE_IP}                        "
echo "  │                                                     "
echo "  │ Installed:                                          "
echo "  │   ✓ Docker CE + Docker Compose                      "
echo "  │   ✓ kubectl (${kubectl_version:-v1.30.2})           "
echo "  │   ✓ kind                                            "
echo "  │   ✓ curl, unzip, tmux, git                         "
echo "  ├────────────────────────────────────────────────────┤"
echo "  │ SSH:                                                "
echo "  │   ${SSH_COMMAND}  "
echo "  └────────────────────────────────────────────────────┘"
echo -e "${NC}"
