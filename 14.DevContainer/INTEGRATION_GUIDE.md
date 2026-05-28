# DevContainer Integration Guide - Step-by-Step

## Before You Start

✅ Have these ready:
- VSCode installed
- Docker Desktop running
- Dev Containers extension installed
- Your `mrbalraj007/Terraform-Drift-Detection` repository cloned

---

## Step 1: Download the Files (10 minutes)

You should have received 6 files:

```
.devcontainer_devcontainer.json
.devcontainer_post-create.sh
.devcontainer_post-start.sh
.devcontainer_Dockerfile
.devcontainer_.env.example
.devcontainer_.gitignore
DEVCONTAINER_README.md
QUICK_REFERENCE.md
```

---

## Step 2: Organize Files in Your Project (5 minutes)

### Open terminal in your project root:

```bash
# Navigate to your Terraform project
cd ~/projects/Terraform-Drift-Detection

# Create .devcontainer directory
mkdir -p .devcontainer

# List current structure (should show at least terraform/ and .github/)
ls -la
```

### Copy files from download location:

**Option A: Using command line**
```bash
# Copy all .devcontainer files to the correct location
cp /path/to/downloads/.devcontainer_devcontainer.json .devcontainer/devcontainer.json
cp /path/to/downloads/.devcontainer_post-create.sh .devcontainer/post-create.sh
cp /path/to/downloads/.devcontainer_post-start.sh .devcontainer/post-start.sh
cp /path/to/downloads/.devcontainer_Dockerfile .devcontainer/Dockerfile
cp /path/to/downloads/.devcontainer_.env.example .devcontainer/.env.example
cp /path/to/downloads/.devcontainer_.gitignore .devcontainer/.gitignore

# Copy documentation files to project root
cp /path/to/downloads/DEVCONTAINER_README.md ./
cp /path/to/downloads/QUICK_REFERENCE.md ./
```

**Option B: Manual (File Explorer)**
1. Create folder: `.devcontainer` in project root
2. Copy the 6 `.devcontainer_*` files into it
3. Rename each file (remove `.devcontainer_` prefix)
4. Copy DEVCONTAINER_README.md and QUICK_REFERENCE.md to project root

### Verify file structure:

```bash
# Your project should now look like this:
your-project/
├── .devcontainer/
│   ├── devcontainer.json       ✓ Main config
│   ├── post-create.sh          ✓ Setup script
│   ├── post-start.sh           ✓ Startup script
│   ├── Dockerfile              ✓ Optional base image
│   ├── .env.example            ✓ Environment template
│   └── .gitignore              ✓ Ignore sensitive files
├── .github/
│   └── workflows/
│       ├── terraform-drift.yml
│       └── ... (your existing workflows)
├── terraform/
│   ├── main.tf
│   └── ... (your terraform code)
├── DEVCONTAINER_README.md      ✓ Full documentation
├── QUICK_REFERENCE.md          ✓ Command cheatsheet
├── README.md                   (your existing readme)
└── ... (other project files)
```

✅ Verify all files are in place:

```bash
ls -la .devcontainer/
# Should show: devcontainer.json, post-create.sh, post-start.sh, Dockerfile, .env.example, .gitignore
```

---

## Step 3: Make Scripts Executable (2 minutes)

```bash
# Make shell scripts executable
chmod +x .devcontainer/post-create.sh
chmod +x .devcontainer/post-start.sh

# Verify
ls -la .devcontainer/
# You should see: -rwxr-xr-x (the 'x' means executable)
```

---

## Step 4: Open Project in VSCode (5 minutes)

### Open the project:

```bash
# Option 1: Command line
code ~/projects/Terraform-Drift-Detection

# Option 2: Use VSCode File menu
# File → Open Folder → Select your project
```

### Wait for VSCode to fully load

Once VSCode opens:
- Wait for explorer to load
- You should see your folder structure on the left

---

## Step 5: Reopen in Container (5 minutes)

### Trigger DevContainer setup:

1. **Open Command Palette:**
   - Press `Ctrl+Shift+P` (Windows/Linux)
   - Press `Cmd+Shift+P` (Mac)

2. **Type the command:**
   ```
   Dev Containers: Reopen in Container
   ```

3. **Click or press Enter**

### First-time setup (3-5 minutes):

VSCode will:
- Build Docker image
- Start container
- Run `post-create.sh` (installs all tools)
- Display setup progress in terminal

**You'll see output like:**
```
[Container] Starting Dev Container
[Container] Installing base packages...
[Container] Installing Terraform...
[Container] Installing Azure CLI...
[Container] Installing MCP servers...
...
[Container] Setup Complete!
```

### Wait for completion:

- Don't close VSCode
- Don't interrupt the process
- First run takes 3-5 minutes (subsequent runs are faster)
- You'll see `✓` marks as each tool installs

---

## Step 6: Verify Installation (3 minutes)

### Open VSCode terminal:

```bash
# Press: Ctrl+` (backtick)
# Or: View → Terminal
```

### Run verification commands:

```bash
# Test each tool
terraform -version
tflint --version
checkov --version
az --version
aws --version
node --version
npm --version
```

✅ All commands should work without errors!

### Check for MCP servers (optional):

```bash
# List installed MCP servers
npm list -g | grep @modelcontextprotocol

# Or:
which terraform-mcp
```

### Verify container status:

Check bottom-left corner of VSCode:
- ✅ Should show: `[Dev Container]` in green
- This confirms you're inside the container

---

## Step 7: Configure Environment Variables (10 minutes)

### Create `.env.local`:

```bash
# Copy template to local config
cp .devcontainer/.env.example .env.local

# Open in editor
nano .env.local
# Or: code .env.local
```

### Edit with your values:

```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
AZURE_TENANT_ID=00000000-0000-0000-0000-000000000000
AZURE_CLIENT_ID=00000000-0000-0000-0000-000000000000

# Storage Account (for Terraform backend)
STORAGE_ACCOUNT_NAME=mystorageaccount
BACKEND_RESOURCE_GROUP=my-terraform-backend-rg

# Slack Webhook (for drift alerts)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXX

# AWS Region (if using AWS)
AWS_REGION=ap-southeast-2
```

### Save file:

- nano: Press `Ctrl+X` → `Y` → `Enter`
- VSCode: Press `Ctrl+S`

### Verify environment is loaded:

```bash
# Reload container or open new terminal
# Check variables
echo $AZURE_SUBSCRIPTION_ID
echo $STORAGE_ACCOUNT_NAME
```

---

## Step 8: Initialize Terraform (10 minutes)

### Prepare backend configuration:

Create file: `backend-azure.hcl` in project root:

```hcl
resource_group_name  = "my-terraform-backend-rg"
storage_account_name = "mystorageaccount"
container_name       = "tfstate"
key                  = "terraform.tfstate"
```

### Authenticate with Azure:

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <YOUR_SUBSCRIPTION_ID>

# Verify login
az account show
```

### Initialize Terraform:

```bash
# Initialize with backend config
terraform init -backend-config=backend-azure.hcl

# Or using Makefile
make init
```

✅ You should see:
```
Initializing the backend...
Successfully configured the backend "azurerm"!

Initializing provider plugins...
Terraform has been successfully initialized!
```

---

## Step 9: Test Security Scanning (5 minutes)

### Run Checkov:

```bash
# Quick security scan
checkov -d terraform/ --framework terraform

# Full report with results
checkov -d . --framework terraform -o cli
```

### Run terraform-compliance:

```bash
# Check compliance
terraform-compliance -f terraform/

# Or with policy file
terraform-compliance -p policies/ -f terraform/
```

### Using Makefile (easier):

```bash
# Run all security checks
make security

# Or individually
make lint
make compliance
```

---

## Step 10: Test Drift Detection (5 minutes)

### Run drift check:

```bash
# The main command you'll use in GitHub Actions
terraform plan -detailed-exitcode
echo "Exit code: $?"

# Exit codes:
# 0 = No changes
# 1 = Error
# 2 = Changes/drift detected
```

### Using Makefile:

```bash
# Easy wrapper
make drift-check

# Output shows if drift detected
```

---

## Step 11: Commit to Git (5 minutes)

### Add .devcontainer to git:

```bash
# Stage the .devcontainer folder
git add .devcontainer/

# Verify files are staged
git status

# Should show:
# new file:   .devcontainer/devcontainer.json
# new file:   .devcontainer/post-create.sh
# ... etc
```

### Create commit:

```bash
# Commit with message
git commit -m "Add DevContainer for Terraform development"

# Optional: Add documentation
git add DEVCONTAINER_README.md QUICK_REFERENCE.md
git commit -m "Add DevContainer documentation"
```

### Push to GitHub:

```bash
# Push changes
git push origin main

# Or your working branch
git push origin <YOUR_BRANCH>
```

✅ Your team can now clone and use the same environment!

---

## Step 12: Share DevContainer with Team (5 minutes)

### Create a message for your team:

```markdown
# Terraform Drift Detection - New DevContainer Environment

We've added a DevContainer configuration to standardize development!

## Quick Start (First Time Only)

1. Clone or pull latest code
2. Open project in VSCode
3. `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
4. Wait 3-5 minutes for setup
5. Done! Everything is pre-installed

## What's Included

- ✅ Terraform, TFLint, Terragrunt
- ✅ Checkov, terraform-compliance, Trivy
- ✅ Azure CLI, AWS CLI
- ✅ Node.js + MCP servers (terraform-mcp, aws-core-mcp, etc.)
- ✅ Go, Python
- ✅ VSCode extensions (Terraform, Azure, Live Share, Copilot)

## Next Steps

1. Copy `.env.example` → `.env.local`
2. Add your Azure subscription and Slack webhook
3. Run: `terraform init -backend-config=backend-azure.hcl`
4. Run: `make validate && make security`

## Get Help

- Full documentation: DEVCONTAINER_README.md
- Quick reference: QUICK_REFERENCE.md
- VSCode Live Share for pair programming!

Questions? Ask in #terraform-drift-alerts Slack channel.
```

### Share via:
- Slack
- Email
- README.md
- Team wiki

---

## Step 13: Test Live Share (Optional, but Awesome!)

### Host setup:

```bash
# Start Live Share session
Ctrl+Shift+P → "Live Share: Start collaboration session"

# Link is copied automatically
# Share with colleague
```

### Guest setup:

```bash
# Receive link from host
# Click the link in browser
# VSCode opens and connects

# You now see:
# - Host's code
# - Host's container tools
# - Shared terminal
# - Real-time collaboration
```

---

## Troubleshooting

### Problem: "Docker daemon not running"

```bash
# Start Docker Desktop
# Or on Linux:
sudo systemctl start docker
```

### Problem: Container build fails

```bash
# Rebuild from scratch
Ctrl+Shift+P → "Dev Containers: Rebuild Container"

# This clears cache and rebuilds
```

### Problem: Tools not found after build

```bash
# Open new terminal (rebuilds container)
Ctrl+Shift+P → "Developer: Reload Window"

# Or restart VSCode
```

### Problem: Can't authenticate with Azure

```bash
# Inside container, login again
az login

# Set subscription
az account set --subscription <ID>

# Verify
az account show
```

### Problem: Terraform init fails

```bash
# Make sure environment variables are set
source .env.local
echo $STORAGE_ACCOUNT_NAME

# Then retry
terraform init -backend-config=backend-azure.hcl
```

---

## Verification Checklist

✅ Before declaring victory, verify:

```bash
# In container terminal, run:

# 1. Files are in place
ls -la .devcontainer/
# Should show: devcontainer.json, post-create.sh, post-start.sh, Dockerfile, .env.example, .gitignore

# 2. Environment is set
echo $AZURE_SUBSCRIPTION_ID
# Should show your subscription ID

# 3. Terraform works
terraform init -backend-config=backend-azure.hcl
# Should say: Successfully configured the backend

# 4. Security scanning works
checkov --version
# Should show version number

# 5. MCP servers installed
npm list -g | grep @modelcontextprotocol
# Should show installed servers

# 6. Live Share available
Ctrl+Shift+P → "Live Share: Start collaboration session"
# Should work without errors

# 7. Git is ready
git status
# Should show clean working directory
```

---

## Next Steps

1. **Daily development**: Just use `Reopen in Container` when opening project
2. **Team onboarding**: Share this guide with new members
3. **CI/CD integration**: Your GitHub Actions workflows can use same tools
4. **Pair programming**: Use Live Share for code reviews
5. **Drift detection**: Watch it run automatically on schedule or manually test

---

## Common Workflows

### Morning Development Session

```bash
# 1. Open project (if not already open)
code ~/projects/Terraform-Drift-Detection

# 2. If new terminal: Container auto-connects
# If this is first time: Ctrl+Shift+P → "Reopen in Container"

# 3. Create feature branch
git checkout -b feature/my-change

# 4. Make changes to terraform/

# 5. Validate and test
make validate
make format
make security
make plan

# 6. Commit
git add terraform/
git commit -m "My terraform change"

# 7. Push
git push origin feature/my-change

# 8. Open PR on GitHub
```

### Code Review Session

```bash
# Receive invite from colleague
git pull origin main

# Open in VSCode
code .

# Get their Live Share link
# Ctrl+Shift+P → "Live Share: Join collaboration session"
# Paste link

# Now you can:
# - See their code in real-time
# - Edit together
# - Run terraform commands in shared terminal
# - Discuss in chat while viewing drift detection logic
```

### Drift Detection Testing

```bash
# Manually test your drift detection workflow
terraform plan -detailed-exitcode
exit_code=$?

if [ $exit_code -eq 2 ]; then
  echo "✓ Drift detected (as expected)"
else
  echo "✓ No drift"
fi

# Or use Makefile
make drift-check

# Watch GitHub Actions run the scheduled job
# https://github.com/mrbalraj007/Terraform-Drift-Detection/actions
```

---

## Success! 🎉

You now have:

✅ DevContainer fully set up  
✅ All tools pre-installed  
✅ Terraform initialized  
✅ Security scanning ready  
✅ Drift detection configured  
✅ Team can clone and develop immediately  
✅ Live Share for collaboration  

**Next: Read DEVCONTAINER_README.md for detailed documentation!**

---

## Need Help?

### Resources

- **DEVCONTAINER_README.md** - Full documentation
- **QUICK_REFERENCE.md** - Command cheatsheet
- **Official Docs** - https://code.visualstudio.com/docs/devcontainers/containers
- **Terraform** - https://www.terraform.io/docs
- **Azure CLI** - https://learn.microsoft.com/en-us/cli/azure/

### Common Issues

If you hit problems, check:

1. Docker is running
2. .devcontainer files exist and are in right location
3. Make scripts executable: `chmod +x .devcontainer/*.sh`
4. Environment variables set in .env.local
5. Azure authentication: `az account show`

---

## Celebrate! 🚀

You're now using a professional, enterprise-grade development environment for infrastructure as code!

Share this with your team and enjoy standardized, reproducible Terraform development.

Happy coding!
