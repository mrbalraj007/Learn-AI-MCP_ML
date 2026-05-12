#!/usr/bin/env bash
# =============================================================================
# setup-bedrock-env.sh
# Universal setup script for Amazon Bedrock AgentCore on Ubuntu 22.04 LTS
# =============================================================================
set -euo pipefail

# --- Colours -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Colour

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_section() { echo -e "\n${BLUE}========== $1 ==========${NC}"; }

# --- Guard: Ubuntu only ------------------------------------------------------
if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
  log_error "This script is designed for Ubuntu 22.04 LTS only."
fi

# =============================================================================
# SECTION 1 - SYSTEM UPDATE
# =============================================================================
log_section "SYSTEM UPDATE (apt)"

log_info "Updating apt package index..."
sudo apt-get update -y
sudo apt-get upgrade -y
log_ok "System packages are up to date."

# =============================================================================
# SECTION 2 - PYTHON 3.12
# =============================================================================
log_section "PYTHON 3.12"

REQUIRED_MAJOR=3
REQUIRED_MINOR=10

install_python312() {
  log_info "Adding deadsnakes PPA for Python 3.12..."
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y ppa:deadsnakes/ppa
  sudo apt-get update -y
  sudo apt-get install -y python3.12 python3.12-venv python3.12-dev
  sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
  log_ok "Python 3.12 installed and set as default python3."
}

if command -v python3 &>/dev/null; then
  PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
  PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
  PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)

  if [ "$PY_MAJOR" -ge "$REQUIRED_MAJOR" ] && [ "$PY_MINOR" -ge "$REQUIRED_MINOR" ]; then
    log_ok "Python $PY_VERSION is already installed and meets the minimum requirement (3.10+). Skipping."
  else
    log_warn "Python $PY_VERSION found but is below 3.10. Installing Python 3.12..."
    install_python312
  fi
else
  log_warn "Python3 not found. Installing Python 3.12..."
  install_python312
fi

python3 --version

# =============================================================================
# SECTION 3 - PIP
# =============================================================================
log_section "PIP"

# Detect the active Python minor version to install the matching pip/venv package
PY_MINOR_ACTIVE=$(python3 -c "import sys; print(sys.version_info.minor)")
PY_MAJOR_ACTIVE=$(python3 -c "import sys; print(sys.version_info.major)")
PY_VER_SHORT="${PY_MAJOR_ACTIVE}.${PY_MINOR_ACTIVE}"   # e.g. 3.10 or 3.12

if python3 -m pip --version &>/dev/null; then
  log_ok "pip is already installed: $(python3 -m pip --version)"
else
  log_info "pip not found. Installing python${PY_VER_SHORT}-specific pip packages..."
  sudo apt-get install -y python3-pip python${PY_VER_SHORT}-dev
  log_ok "pip installed: $(python3 -m pip --version)"
fi

# =============================================================================
# SECTION 4 - PYTHON VIRTUAL ENVIRONMENT (bedrock-env)
# =============================================================================
log_section "PYTHON VIRTUAL ENVIRONMENT (bedrock-env)"

# Ensure python3-venv is installed for the active Python version
# IMPORTANT: On Ubuntu/Debian dpkg -l can show a package as installed
# even when the venv/ensurepip modules are broken. Always verify with
# a direct Python import test - that is the only reliable check.
log_info "Verifying python venv and ensurepip modules are functional..."
if python3 -c "import ensurepip, venv" &>/dev/null; then
  log_ok "python${PY_VER_SHORT} venv and ensurepip modules are working."
else
  log_warn "venv/ensurepip modules not functional. Force-reinstalling python${PY_VER_SHORT}-venv..."
  sudo apt-get install -y --reinstall "python${PY_VER_SHORT}-venv"
  # Second attempt after reinstall
  if python3 -c "import ensurepip, venv" &>/dev/null; then
    log_ok "python${PY_VER_SHORT}-venv reinstalled and verified working."
  else
    log_warn "Still not working after reinstall. Trying python3-venv fallback package..."
    sudo apt-get install -y --reinstall python3-venv python3-full
    python3 -c "import ensurepip, venv" \
      || log_error "Could not fix ensurepip. Try: sudo apt purge python3.10-venv && sudo apt install python3.10-venv"
  fi
fi

VENV_DIR="$HOME/bedrock-env"

if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/activate" ]; then
  log_ok "Virtual environment already exists at $VENV_DIR. Skipping creation."
else
  log_info "Creating virtual environment at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
  log_ok "Virtual environment created at $VENV_DIR."
fi

log_info "Activating virtual environment..."
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
log_ok "Virtual environment activated: $(which python3)"

# =============================================================================
# SECTION 5 - BOTO3 AND BOTOCORE (pinned versions)
# =============================================================================
log_section "BOTO3 == 1.40.49 and BOTOCORE == 1.40.49"

BOTO3_REQUIRED="1.40.49"
BOTOCORE_REQUIRED="1.40.49"

BOTO3_INSTALLED=$(pip show boto3 2>/dev/null | grep "^Version:" | awk '{print $2}' || true)
BOTOCORE_INSTALLED=$(pip show botocore 2>/dev/null | grep "^Version:" | awk '{print $2}' || true)

if [ "$BOTO3_INSTALLED" = "$BOTO3_REQUIRED" ] && [ "$BOTOCORE_INSTALLED" = "$BOTOCORE_REQUIRED" ]; then
  log_ok "boto3==$BOTO3_REQUIRED and botocore==$BOTOCORE_REQUIRED already installed. Skipping."
else
  log_info "Installing boto3==$BOTO3_REQUIRED botocore==$BOTOCORE_REQUIRED..."
  pip install --quiet boto3==${BOTO3_REQUIRED} botocore==${BOTOCORE_REQUIRED}
  log_ok "Installed:"
fi

pip show boto3  | grep Version
pip show botocore | grep Version

# =============================================================================
# SECTION 6 - AWS CLI
# =============================================================================
log_section "AWS CLI"

if command -v aws &>/dev/null; then
  log_ok "AWS CLI is already installed: $(aws --version)"
else
  log_info "AWS CLI not found. Installing via pip..."
  pip install --quiet --upgrade awscli
  log_ok "AWS CLI installed: $(aws --version)"
fi

# AWS configure prompt
echo ""
log_warn "--------------------------------------------------------------"
log_warn "ACTION REQUIRED: Configure AWS CLI for MyAgentCoreUser."
log_warn "Have your Access Key ID and Secret Access Key ready."
log_warn "Recommended settings:"
log_warn "  Default region     : us-east-1"
log_warn "  Default output     : json"
log_warn "--------------------------------------------------------------"
read -rp "Do you want to run 'aws configure' now? [y/N]: " RUN_CONFIGURE
if [[ "$RUN_CONFIGURE" =~ ^[Yy]$ ]]; then
  aws configure
  log_ok "AWS CLI configured."
else
  log_info "Skipping aws configure. Run it manually when ready: aws configure"
fi

# =============================================================================
# SECTION 7 - UV (Astral)
# =============================================================================
log_section "UV (Astral package manager)"

if command -v uv &>/dev/null; then
  log_ok "uv is already installed: $(uv --version)"
else
  log_info "Installing uv via official installer..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Add uv to PATH for the remainder of this script
  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
  log_ok "uv installed: $(uv --version)"
fi

# =============================================================================
# SECTION 8 - BEDROCK AGENTCORE STARTER TOOLKIT
# =============================================================================
log_section "BEDROCK AGENTCORE STARTER TOOLKIT"

if pip show bedrock-agentcore-starter-toolkit &>/dev/null; then
  TOOLKIT_VERSION=$(pip show bedrock-agentcore-starter-toolkit | grep "^Version:" | awk '{print $2}')
  log_ok "bedrock-agentcore-starter-toolkit==$TOOLKIT_VERSION already installed. Skipping."
else
  log_info "Installing bedrock-agentcore-starter-toolkit via uv pip..."
  uv pip install bedrock-agentcore-starter-toolkit
  log_ok "bedrock-agentcore-starter-toolkit installed."
fi

# =============================================================================
# SUMMARY
# =============================================================================
log_section "SETUP COMPLETE - VERSION SUMMARY"

echo ""
printf "%-40s %s\n" "Component" "Version"
printf "%-40s %s\n" "---------" "-------"
printf "%-40s %s\n" "Python3"                   "$(python3 --version 2>&1)"
printf "%-40s %s\n" "pip"                        "$(pip --version 2>&1 | cut -d' ' -f1-2)"
printf "%-40s %s\n" "boto3"                      "$(pip show boto3 2>/dev/null | grep Version || echo 'not found')"
printf "%-40s %s\n" "botocore"                   "$(pip show botocore 2>/dev/null | grep Version || echo 'not found')"
printf "%-40s %s\n" "AWS CLI"                    "$(aws --version 2>&1)"
printf "%-40s %s\n" "uv"                         "$(uv --version 2>&1)"
printf "%-40s %s\n" "bedrock-agentcore-toolkit"  "$(pip show bedrock-agentcore-starter-toolkit 2>/dev/null | grep Version || echo 'not found')"
printf "%-40s %s\n" "Virtual Env"                "$VENV_DIR"

echo ""
log_ok "All done! To activate the virtual environment in a new terminal, run:"
echo -e "  ${GREEN}source ~/bedrock-env/bin/activate${NC}"
echo ""