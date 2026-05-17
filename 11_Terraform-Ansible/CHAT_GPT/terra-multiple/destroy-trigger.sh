#!/bin/bash
set -euo pipefail

cd terraform || exit 1

terraform fmt
# terraform plan
terraform destroy -auto-approve

# REMOTE_USER="dc-ops"
# REMOTE_HOST="192.168.1.212"
# LOCAL_KEY="/home/dc-ops/terra-1/terraform/devtools-key.pem"
# REMOTE_KEY_DIR="/home/dc-ops/.ssh"
# REMOTE_KEY_PATH="${REMOTE_KEY_DIR}/$(basename "$LOCAL_KEY")"

# echo "Preparing remote .ssh directory..."
# ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
#   -i ~/.ssh/id_rsa "${REMOTE_USER}@${REMOTE_HOST}" \
#   "mkdir -p '${REMOTE_KEY_DIR}'"

# echo "Removing old remote key if it exists..."
# ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
#   -i ~/.ssh/id_rsa "${REMOTE_USER}@${REMOTE_HOST}" \
#   "rm -f '${REMOTE_KEY_PATH}'"

# echo "Copying SSH key to Ansible Server..."
# scp -o BatchMode=yes -o StrictHostKeyChecking=no \
#   -i ~/.ssh/id_rsa \
#   "$LOCAL_KEY" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_KEY_PATH}"

# chmod 600 "$LOCAL_KEY"

# sleep 20

# echo "Waiting for Ansible server for SSH..."

# until ssh -o BatchMode=yes -o ConnectTimeout=5 \
#   -i ~/.ssh/id_rsa "${REMOTE_USER}@${REMOTE_HOST}" "echo ok" 2>/dev/null
# do
#   sleep 10
# done

# echo "SSH is ready. Running Ansible Playbook..."

# ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
#   -i ~/.ssh/id_rsa "${REMOTE_USER}@${REMOTE_HOST}" "
# source ~/ansible-venv/bin/activate && \
# cd ~/ans-1/ansible && \
# ansible-playbook playbooks/install-tools.yml
# "