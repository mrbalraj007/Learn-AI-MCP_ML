#!/bin/bash
set -euo pipefail

# ── Defaults ──
ANSIBLE_HOST="${ANSIBLE_HOST:-192.168.1.212}"
ANSIBLE_USER="${ANSIBLE_USER:-dc-ops}"
ANSIBLE_KEY="${ANSIBLE_KEY:-~/.ssh/id_rsa}"
ANSIBLE_PROJECT_DIR="${ANSIBLE_PROJECT_DIR:-~/ans-1/ansible}"
ANSIBLE_VENV="${ANSIBLE_VENV:-~/ansible-venv}"
ANSIBLE_PLAYBOOK_UBUNTU="${ANSIBLE_PLAYBOOK_UBUNTU:-playbooks/ubuntu-install-tools.yml}"
ANSIBLE_PLAYBOOK_WINDOWS="${ANSIBLE_PLAYBOOK_WINDOWS:-playbooks/windows-install-iis.yml}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY_SRC="${SCRIPT_DIR}/terraform/ansible_inventory.ini"
SSH_KEY_SRC="${SCRIPT_DIR}/terraform/devtools-key.pem"
SSH_KEY_DST="/home/${ANSIBLE_USER}/.ssh/devtools-key.pem"

# ── Parse overrides ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ansible-host) ANSIBLE_HOST="$2"; shift 2 ;;
    --ansible-user) ANSIBLE_USER="$2"; shift 2 ;;
    --ansible-key)  ANSIBLE_KEY="$2";  shift 2 ;;
    --ansible-dir)  ANSIBLE_PROJECT_DIR="$2"; shift 2 ;;
    --playbook-ubuntu) ANSIBLE_PLAYBOOK_UBUNTU="$2"; shift 2 ;;
    --playbook-windows) ANSIBLE_PLAYBOOK_WINDOWS="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "  --ansible-host HOST        Ansible server hostname or IP"
      echo "  --ansible-user USER        SSH user for Ansible server"
      echo "  --ansible-key  PATH        SSH private key path"
      echo "  --ansible-dir  DIR         Ansible project directory on remote"
      echo "  --playbook-ubuntu PATH     Ubuntu playbook path (default: playbooks/ubuntu-install-tools.yml)"
      echo "  --playbook-windows PATH    Windows playbook path (default: playbooks/windows-install-iis.yml)"
      exit 0 ;;
    *) shift ;;
  esac
done

# ── Terraform apply ──
cd "${SCRIPT_DIR}/terraform"
terraform fmt
terraform init -input=false
terraform apply -auto-approve

# ── Wait for Ansible server ──
echo "Waiting for Ansible server (${ANSIBLE_HOST}) to be reachable..."
for i in $(seq 1 30); do
  if ssh -o BatchMode=yes -o ConnectTimeout=5 \
    -i "${ANSIBLE_KEY}" "${ANSIBLE_USER}@${ANSIBLE_HOST}" "echo ok" 2>/dev/null; then
    break
  fi
  sleep 10
done

# ── Transfer files ──
echo "Transferring inventory and SSH key to Ansible server..."
scp -o BatchMode=yes -i "${ANSIBLE_KEY}" \
  "${INVENTORY_SRC}" "${ANSIBLE_USER}@${ANSIBLE_HOST}:${ANSIBLE_PROJECT_DIR}/inventory/hosts.ini"

scp -o BatchMode=yes -i "${ANSIBLE_KEY}" \
  "${SSH_KEY_SRC}" "${ANSIBLE_USER}@${ANSIBLE_HOST}:${SSH_KEY_DST}"

ssh -o BatchMode=yes -i "${ANSIBLE_KEY}" "${ANSIBLE_USER}@${ANSIBLE_HOST}" \
  "chmod 600 ${SSH_KEY_DST}"

echo "Waiting 3 minutes for Ubuntu instance to finish initializing..."
sleep 180

# ── Run playbooks ──
echo "Running Ubuntu playbook (targeting [linux] group)..."
ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
  -i "${ANSIBLE_KEY}" "${ANSIBLE_USER}@${ANSIBLE_HOST}" "
source ${ANSIBLE_VENV}/bin/activate && \
cd ${ANSIBLE_PROJECT_DIR} && \
ansible-playbook -i inventory/hosts.ini ${ANSIBLE_PLAYBOOK_UBUNTU} --limit linux
"

echo "Waiting 3 minutes for Windows instance to finish initializing..."
sleep 180

echo "Running Windows playbook (targeting [windows] group)..."
ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
  -i "${ANSIBLE_KEY}" "${ANSIBLE_USER}@${ANSIBLE_HOST}" "
source ${ANSIBLE_VENV}/bin/activate && \
cd ${ANSIBLE_PROJECT_DIR} && \
ansible-playbook -i inventory/hosts.ini ${ANSIBLE_PLAYBOOK_WINDOWS} --limit windows
"

echo "Done. Both playbooks executed."