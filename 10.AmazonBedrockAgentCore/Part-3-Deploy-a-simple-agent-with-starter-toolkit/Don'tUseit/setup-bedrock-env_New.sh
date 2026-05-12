#!/usr/bin/env bash
# =============================================================================
# setup-bedrock-env.sh
# Stable Amazon Bedrock AgentCore setup for Ubuntu 22.04
# =============================================================================

set -euo pipefail

# =============================================================================
# COLORS
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_section() { echo -e "\n${BLUE}========== $1 ==========${NC}"; }

# =============================================================================
# UBUNTU CHECK
# =============================================================================
if ! grep -qi ubuntu /etc/os-release; then
  log_error "Ubuntu required."
fi

# =============================================================================
# SYSTEM UPDATE
# =============================================================================
log_section "SYSTEM UPDATE"

sudo apt-get update -y

sudo apt-get install -y \
  curl \
  wget \
  unzip \
  zip \
  jq \
  git \
  build-essential \
  software-properties-common \
  ca-certificates \
  gnupg \
  lsb-release

log_ok "Base packages installed."

# =============================================================================
# FIX BROKEN apt_pkg (IF NEEDED)
# =============================================================================
log_section "FIXING PYTHON apt_pkg"

if ! python3 -c "import apt_pkg" &>/dev/null; then
  log_warn "apt_pkg missing. Repairing Ubuntu Python packages..."

  sudo apt-get install --reinstall -y \
    python3-apt \
    command-not-found

  log_ok "apt_pkg repaired."
else
  log_ok "apt_pkg working."
fi

# =============================================================================
# PYTHON 3.12
# =============================================================================
log_section "PYTHON 3.12"

install_python312() {
  sudo add-apt-repository -y ppa:deadsnakes/ppa
  sudo apt-get update -y

  sudo apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev

  log_ok "Python 3.12 installed."
}

if command -v python3.12 &>/dev/null; then
  log_ok "Python 3.12 already installed."
else
  install_python312
fi

python3.12 --version

# =============================================================================
# NODE.JS 22
# =============================================================================
log_section "NODE.JS 22"

install_node() {
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
  log_ok "Node.js installed."
}

if command -v node &>/dev/null; then
  NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)

  if [ "$NODE_MAJOR" -ge 22 ]; then
    log_ok "Node.js already installed: $(node -v)"
  else
    log_warn "Old Node.js version detected: $(node -v). Upgrading..."
    install_node
  fi
else
  install_node
fi

echo ""
node --version
npm --version

# =============================================================================
# REMOVE OLD BROKEN AWS CLI
# =============================================================================
log_section "REMOVE BROKEN AWS CLI"

rm -f "$HOME/bedrock-env/bin/aws" || true
sudo rm -rf /usr/local/aws-cli || true
sudo rm -f /usr/local/bin/aws || true

log_ok "Old AWS CLI removed."

# =============================================================================
# INSTALL AWS CLI V2
# =============================================================================
log_section "AWS CLI V2"

(
  cd /tmp
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
  unzip -oq awscliv2.zip
  sudo ./aws/install --update
  rm -rf aws awscliv2.zip
)

log_ok "AWS CLI v2 installed."
aws --version

# =============================================================================
# PYTHON VENV
# =============================================================================
log_section "PYTHON VIRTUAL ENVIRONMENT"

VENV_DIR="$HOME/bedrock-env"

if [ -d "$VENV_DIR" ]; then
  log_warn "Removing old virtual environment..."
  rm -rf "$VENV_DIR"
fi

log_info "Creating fresh Python 3.12 virtual environment..."
python3.12 -m venv "$VENV_DIR"

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

log_ok "Virtual environment activated."
python --version

# =============================================================================
# UPGRADE PIP
# =============================================================================
log_section "UPGRADE PIP"

pip install --upgrade pip setuptools wheel

# =============================================================================
# INSTALL UV
# =============================================================================
log_section "INSTALL UV"

if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh

  # Persist uv on PATH for future shell sessions
  UV_PATH_LINE='export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"'

  for RC in "$HOME/.bashrc" "$HOME/.profile"; do
    if [ -f "$RC" ] && ! grep -qF '.local/bin' "$RC"; then
      echo "$UV_PATH_LINE" >> "$RC"
      log_info "uv PATH added to $RC"
    fi
  done

  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi

uv --version

# =============================================================================
# INSTALL PYTHON LIBRARIES
# =============================================================================
log_section "INSTALL PYTHON LIBRARIES"

pip install --upgrade \
  boto3==1.40.49 \
  botocore==1.40.49

pip show boto3   | grep Version
pip show botocore | grep Version

# =============================================================================
# INSTALL AGENTCORE CLI
# =============================================================================
log_section "INSTALL AGENTCORE CLI"

# FIX: correct package is @aws/agentcore (NOT @aws/agentcore-cli)
sudo npm uninstall -g @aws/agentcore 2>/dev/null || true
sudo npm cache clean --force

# --legacy-peer-deps avoids peer dependency conflicts on Node 22
sudo npm install -g @aws/agentcore --legacy-peer-deps

log_ok "AgentCore CLI installed."

agentcore --help >/dev/null 2>&1 || true

# =============================================================================
# AWS CONFIGURE
# =============================================================================
log_section "AWS CONFIGURATION"

echo ""
echo "Run AWS configure using your IAM credentials."
echo ""

# Only prompt if stdin is a real terminal (avoids hanging in CI/piped mode)
if [ -t 0 ]; then
  read -rp "Run aws configure now? [y/N]: " RUNCFG
  if [[ "$RUNCFG" =~ ^[Yy]$ ]]; then
    aws configure
  fi
else
  log_warn "Non-interactive mode detected. Skipping aws configure."
  log_warn "Run 'aws configure' manually after the script completes."
fi

# =============================================================================
# SUMMARY
# =============================================================================
log_section "SUMMARY"

echo ""
printf "%-25s %s\n" "Python"    "$(python --version)"
printf "%-25s %s\n" "pip"       "$(pip --version | awk '{print $1,$2}')"
printf "%-25s %s\n" "Node.js"   "$(node --version)"
printf "%-25s %s\n" "npm"       "$(npm --version)"
printf "%-25s %s\n" "AWS CLI"   "$(aws --version)"
printf "%-25s %s\n" "uv"        "$(uv --version)"
printf "%-25s %s\n" "AgentCore" "$(agentcore --version 2>/dev/null || echo 'installed')"

echo ""
log_ok "SETUP COMPLETED SUCCESSFULLY"

echo ""
echo "Activate environment:"
echo ""
echo "  source ~/bedrock-env/bin/activate"
echo ""
echo "Deploy:"
echo ""
echo "  agentcore deploy"
echo ""