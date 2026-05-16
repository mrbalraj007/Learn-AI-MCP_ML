#!/usr/bin/env bash
###############################################################################
# destroy.sh — Tear down all Terraform-managed AWS resources
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

log()     { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

echo -e "${RED}⚠️  WARNING: This will DESTROY all resources created by Terraform.${NC}"
read -r -p "Are you sure? Type 'yes' to confirm: " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
  warn "Destroy cancelled."
  exit 0
fi

cd "${TERRAFORM_DIR}"

log "Running terraform destroy..."
terraform destroy -auto-approve

# Clean up local artefacts
log "Cleaning up local artefacts..."
rm -f ../ansible/*.pem
rm -f ../ansible/inventory/static_hosts.ini
rm -f tfplan

success "All resources destroyed and artefacts cleaned up."
