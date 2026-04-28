#!/bin/bash
# ============================================================
#  Post-Install Cleanup Script
#  Ubuntu 22.04 — DevOps Setup (VS Code, Claude, Terraform,
#  AWS CLI, Ollama, MCP Servers)
#  Run AFTER all phases are verified working.
# ============================================================

set -e
BEFORE=$(df -h / | awk 'NR==2{print $3}')
echo "================================================"
echo "  Disk used BEFORE cleanup: $BEFORE"
echo "================================================"

# ------------------------------------------------------------
# 1. AWS CLI v2 — installer zip + extracted folder
# ------------------------------------------------------------
echo "[1/9] AWS CLI installer files..."
rm -f  ~/awscliv2.zip
rm -rf ~/aws/
echo "    ✅ done"

# ------------------------------------------------------------
# 2. Go tarball (kept binary in /usr/local/go, tarball unneeded)
# ------------------------------------------------------------
echo "[2/9] Go tarball..."
rm -f ~/go1.*.linux-amd64.tar.gz
echo "    ✅ done"

# ------------------------------------------------------------
# 3. kubectl downloaded binary (already moved to /usr/local/bin)
# ------------------------------------------------------------
echo "[3/9] kubectl download file..."
rm -f ~/kubectl
echo "    ✅ done"

# ------------------------------------------------------------
# 4. APT — package list cache + orphaned packages
# ------------------------------------------------------------
echo "[4/9] APT cache + orphaned packages..."
sudo apt autoremove -y --purge
sudo apt autoclean -y
sudo apt clean
echo "    ✅ done"

# ------------------------------------------------------------
# 5. npm cache (global + user)
# ------------------------------------------------------------
echo "[5/9] npm cache..."
npm cache clean --force
echo "    ✅ done"

# ------------------------------------------------------------
# 6. pip / pip3 cache
# ------------------------------------------------------------
echo "[6/9] pip cache..."
pip3 cache purge 2>/dev/null || true
echo "    ✅ done"

# ------------------------------------------------------------
# 7. uv cache (Python packages downloaded for MCP servers)
# ------------------------------------------------------------
echo "[7/9] uv cache..."
uv cache clean 2>/dev/null || true
echo "    ✅ done"

# ------------------------------------------------------------
# 8. Snap cache (Ubuntu 22.04 ships with snapd)
# ------------------------------------------------------------
echo "[8/9] Snap old revisions..."
snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | \
  while read snapname revision; do
    sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
  done
echo "    ✅ done"

# ------------------------------------------------------------
# 9. Thumbnail + trash + temp files
# ------------------------------------------------------------
echo "[9/9] Thumbnails, trash, /tmp leftovers..."
rm -rf ~/.cache/thumbnails/*
rm -rf ~/.local/share/Trash/files/*
rm -rf ~/.local/share/Trash/info/*
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
echo "    ✅ done"

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------
AFTER=$(df -h / | awk 'NR==2{print $3}')
echo ""
echo "================================================"
echo "  Disk used BEFORE: $BEFORE"
echo "  Disk used AFTER:  $AFTER"
echo "================================================"
echo "  ✅ Cleanup complete!"
echo ""
echo "  NOTE: Ollama models are large (2–7 GB each)."
echo "  To remove unused models run:"
echo "    ollama list"
echo "    ollama rm <model-name>"
echo "================================================"
