#!/bin/bash
set -euo pipefail

# ── Defaults ──
ANSIBLE_HOST="${ANSIBLE_HOST:-192.168.1.212}"
ANSIBLE_USER="${ANSIBLE_USER:-dc-ops}"
ANSIBLE_KEY="${ANSIBLE_KEY:-~/.ssh/id_rsa}"
ANSIBLE_PROJECT_DIR="${ANSIBLE_PROJECT_DIR:-~/ans-1/ansible}"
ANSIBLE_VENV="${ANSIBLE_VENV:-~/ansible-venv}"
CLEANUP_PLAYBOOK="${CLEANUP_PLAYBOOK:-playbooks/install-tools.yml}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY_SRC="${SCRIPT_DIR}/terraform/ansible_inventory.ini"

# ── Parse overrides ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ansible-host) ANSIBLE_HOST="$2"; shift 2 ;;
    --ansible-user) ANSIBLE_USER="$2"; shift 2 ;;
    --ansible-key)  ANSIBLE_KEY="$2";  shift 2 ;;
    --ansible-dir)  ANSIBLE_PROJECT_DIR="$2"; shift 2 ;;
    --cleanup-playbook) CLEANUP_PLAYBOOK="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "  --ansible-host HOST       Ansible server hostname or IP"
      echo "  --ansible-user USER       SSH user for Ansible server"
      echo "  --ansible-key  PATH       SSH private key path"
      echo "  --ansible-dir  DIR        Ansible project directory on remote"
      echo "  --cleanup-playbook PATH   Cleanup playbook path relative to ansible-dir"
      exit 0 ;;
    *) shift ;;
  esac
done

# ── Optional: run cleanup playbook before destroy ──
if [ -f "${INVENTORY_SRC}" ]; then
  echo "Running cleanup playbook on Ansible server..."
  scp -o BatchMode=yes -i "${ANSIBLE_KEY}" \
    "${INVENTORY_SRC}" "${ANSIBLE_USER}@${ANSIBLE_HOST}:${ANSIBLE_PROJECT_DIR}/inventory/hosts.ini" 2>/dev/null || true

  ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
    -i "${ANSIBLE_KEY}" "${ANSIBLE_USER}@${ANSIBLE_HOST}" "
  source ${ANSIBLE_VENV}/bin/activate && \
  cd ${ANSIBLE_PROJECT_DIR} && \
  ansible-playbook -i inventory/hosts.ini ${CLEANUP_PLAYBOOK}
  " 2>/dev/null || true
fi

# ── Terraform destroy ──
cd "${SCRIPT_DIR}/terraform"
terraform fmt
terraform destroy -auto-approve

# ── Clean up local inventory ──
echo "Deleting ansible_inventory.ini..."
rm -f ansible_inventory.ini

echo "Destroy complete."