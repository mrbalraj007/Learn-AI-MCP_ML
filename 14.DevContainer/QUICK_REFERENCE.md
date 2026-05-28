# DevContainer & Terraform Drift Detection - Quick Reference

## DevContainer Commands

### Open/Manage Container

```bash
# Reopen project in container (first time)
Ctrl+Shift+P → "Dev Containers: Reopen in Container"

# Rebuild container (if config changed)
Ctrl+Shift+P → "Dev Containers: Rebuild Container"

# Reopen locally (exit container)
Ctrl+Shift+P → "Dev Containers: Reopen Locally"

# View container logs
Ctrl+Shift+P → "Dev Containers: Show Container Logs"

# Add devcontainer config to existing project
Ctrl+Shift+P → "Dev Containers: Add Dev Container Config Files"
```

### Terminal Shortcuts

```bash
# Open integrated terminal
Ctrl+`  (backtick/grave accent)

# New terminal
Ctrl+Shift+`

# Split terminal
Ctrl+Shift+5
```

---

## Terraform Commands (In Container)

### Initialize & Setup

```bash
# Initialize Terraform
terraform init

# Initialize with backend configuration
terraform init -backend-config=backend-azure.hcl

# Reconfigure backend
terraform init -reconfigure -backend-config=backend-azure.hcl

# Upgrade Terraform version
terraform init -upgrade
```

### Validation & Formatting

```bash
# Validate Terraform syntax
terraform validate

# Format code (recursive)
terraform fmt -recursive

# Check format without changing
terraform fmt -recursive -check

# Format specific file
terraform fmt main.tf
```

### Planning & Applying

```bash
# Generate and display plan
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Show saved plan
terraform show tfplan

# Apply saved plan
terraform apply tfplan

# Apply without plan (faster for small changes)
terraform apply -auto-approve

# Apply with variables
terraform apply -var="key=value" -auto-approve
```

### Drift Detection (Your Main Use Case!)

```bash
# Check for drift with exit code
terraform plan -detailed-exitcode
# Exit codes: 0=no changes, 1=error, 2=drift/changes detected

# Store exit code in variable
terraform plan -detailed-exitcode; exit_code=$?
echo "Exit code: $exit_code"

# Run in CI/CD style (your GitHub Actions approach)
terraform plan -detailed-exitcode
if [ $? -eq 2 ]; then
  echo "✓ Drift detected!"
  # Send alert (Slack, etc.)
else
  echo "✓ No drift"
fi

# Using Makefile (easier)
make drift-check
```

### Destroy & Cleanup

```bash
# Plan destruction
terraform plan -destroy

# Destroy with confirmation
terraform destroy

# Destroy without confirmation (use carefully!)
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=azurerm_resource_group.example
```

### Inspection & State Management

```bash
# List resources in state
terraform state list

# Show resource details
terraform state show azurerm_resource_group.example

# Remove resource from state (without deleting)
terraform state rm azurerm_resource_group.example

# Replace resource
terraform state replace-provider \
  hashicorp/azurerm \
  registry.terraform.io/hashicorp/azurerm

# Refresh state (sync with actual resources)
terraform refresh

# View state file (use carefully!)
cat terraform.tfstate | jq .

# Backup state
cp terraform.tfstate terraform.tfstate.backup
```

### Debugging & Logs

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan

# Disable logging
unset TF_LOG
unset TF_LOG_PATH

# View logs
tail -f terraform-debug.log

# Show detailed error
terraform plan -lock=false 2>&1 | grep -A 20 "Error"
```

---

## Security Scanning (Your Workflow)

### Checkov (Security & Compliance)

```bash
# Scan directory
checkov -d .

# Scan with specific framework
checkov -d . --framework terraform

# Scan and output to JSON
checkov -d . --framework terraform -o json > checkov-report.json

# Skip specific checks
checkov -d . --skip-check CKV_AZURE_59,CKV2_AZURE_40

# Check specific check only
checkov -d . --check CKV_AZURE_59

# View all available checks
checkov --list
```

### terraform-compliance (Policy & Compliance)

```bash
# Run compliance checks
terraform-compliance -f . -p policies/

# With specific policy file
terraform-compliance -p ./policies/policy.json -d .

# Show available tags
terraform-compliance -t
```

### Trivy (Container Image Vulnerability)

```bash
# Scan Docker image
trivy image python:3.11

# Scan filesystem
trivy fs .

# Generate report
trivy image --format json --output report.json python:3.11
```

---

## Makefile Commands (Pre-configured in Container)

```bash
# Show all available commands
make help

# Initialize Terraform
make init

# Validate syntax
make validate

# Format code
make format

# Run TFLint
make lint

# Run security scan (Checkov)
make security

# Run compliance scan
make compliance

# Generate plan
make plan

# Apply changes
make apply

# Destroy infrastructure
make destroy

# Check for drift (uses detailed-exitcode)
make drift-check

# Clean Terraform cache
make clean
```

---

## Live Share (Team Collaboration)

### Host (Share Your Code)

```bash
# Start collaboration session
Ctrl+Shift+P → "Live Share: Start collaboration session"

# Copy invitation link
Ctrl+Shift+P → "Live Share: Copy Invitation Link"

# End session
Ctrl+Shift+P → "Live Share: End collaboration session"

# Set read-only mode for guests
Click on "Live Share" icon → Settings → Guest read-only
```

### Guest (Join Collaboration)

```bash
# Join via link (paste in browser)
https://prod.liveshare.vsengsaas.visualstudio.com/join?...

# Or: Click link directly
VSCode opens → Connects to host's session
```

### Live Share Tips for Terraform Review

```bash
# Host + Guest both see:
- Same files (host's .devcontainer environment)
- Shared terminal output
- Each other's cursors
- Same debugging session

# Perfect for:
- Reviewing drift detection logic
- Debugging Terraform errors
- Pair programming on infrastructure
- Quick code review before merge
```

---

## Azure CLI Commands (For OIDC Setup)

### Authentication

```bash
# Login to Azure
az login

# Login with specific tenant
az login --tenant <TENANT_ID>

# Show current account
az account show

# List all accounts
az account list

# Set subscription
az account set --subscription <SUBSCRIPTION_ID>

# Clear credentials
az logout
```

### Service Principal (OIDC)

```bash
# Create service principal for OIDC
az ad sp create-for-rbac \
  --name "demo-github-azure-oidc-connection" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

# List service principals
az ad sp list --all

# Get details
az ad sp show --id <CLIENT_ID>

# Reset credentials
az ad sp credential reset --name <NAME>
```

### Storage Account (Remote Backend)

```bash
# Create storage account
az storage account create \
  --name mystorageaccount \
  --resource-group my-terraform-backend-rg \
  --location eastus

# Create container
az storage container create \
  --name tfstate \
  --account-name mystorageaccount

# List containers
az storage container list --account-name mystorageaccount

# Set access level
az storage container set-permission \
  --name tfstate \
  --account-name mystorageaccount \
  --public-access off
```

---

## AWS CLI Commands (For AWS Resources)

### Configuration

```bash
# Configure credentials
aws configure

# Configure specific profile
aws configure --profile myprofile

# Show configuration
aws configure list

# Set region
export AWS_REGION=ap-southeast-2
```

### STS (Security Token Service)

```bash
# Get current identity
aws sts get-caller-identity

# Get temporary credentials
aws sts get-session-token

# Assume role
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT:role/ROLE --role-session-name session
```

### EC2 & Infrastructure

```bash
# List instances
aws ec2 describe-instances

# List VPCs
aws ec2 describe-vpcs

# List security groups
aws ec2 describe-security-groups
```

---

## Git Commands (Useful in Workflow)

### Branches & Commits

```bash
# Create and checkout branch
git checkout -b feature/drift-detection

# Check status
git status

# Stage changes
git add .
git add terraform/*.tf

# Commit (will skip CI with message)
git commit -m "Update drift detection logic [skip ci]"

# Push branch
git push origin feature/drift-detection

# Create pull request
# Go to GitHub and create PR for review
```

### Sync & Pull

```bash
# Fetch latest
git fetch origin

# Pull latest
git pull origin main

# Rebase on main (cleaner history)
git rebase origin/main

# Pull with rebase
git pull --rebase origin main
```

---

## Environment Variables

### Quick Setup

```bash
# Source environment file
source .env.local

# Check variables
echo $AZURE_SUBSCRIPTION_ID
echo $STORAGE_ACCOUNT_NAME
echo $SLACK_WEBHOOK_URL

# Set temporarily
export TERRAFORM_VERSION=1.10

# Unset variable
unset TERRAFORM_VERSION
```

---

## Useful VSCode Shortcuts

```bash
Ctrl+Shift+P        Command Palette (everything)
Ctrl+K Ctrl+S       Keyboard Shortcuts
Ctrl+`              Toggle Terminal
Ctrl+B              Toggle Explorer
Ctrl+Shift+D        Debug View
Ctrl+Shift+X        Extensions
Ctrl+Shift+E        Explorer
Ctrl+Shift+F        Find in Files
Ctrl+H              Find & Replace
Ctrl+L              Select Current Line
Ctrl+/              Toggle Comment
Alt+Up/Down         Move Line Up/Down
Ctrl+D              Select Word
Ctrl+Shift+L        Select All Occurrences
F12                 Go to Definition
Shift+F12           Show References
```

---

## Troubleshooting Commands

```bash
# Check container is running
docker ps | grep terraform

# View container logs
docker logs <CONTAINER_ID>

# Restart container
Ctrl+Shift+P → "Dev Containers: Rebuild Container"

# Check disk space (in container)
df -h

# Check memory usage
free -h

# Check running processes
ps aux | grep terraform

# Test Azure connection
az account show

# Test AWS connection
aws sts get-caller-identity

# Test internet connectivity
ping google.com

# Clear npm cache
npm cache clean --force

# Reinstall tools
pip3 install --upgrade terraform-compliance checkov
npm install -g @modelcontextprotocol/server-terraform
```

---

## Files & Directories

```bash
# Container workspace root
/workspace

# Terraform plugin cache
/workspace/.terraform/cache

# Logs directory
/workspace/.terraform-logs

# Plans directory
/workspace/terraform-plans

# State files (usually in remote backend)
/workspace/terraform.tfstate*

# Home directory
/root

# Azure credentials
/root/.azure

# AWS credentials
/root/.aws

# SSH keys (mounted from host)
/root/.ssh
```

---

## Common Workflow

```bash
# 1. Branch for feature
git checkout -b feature/my-change

# 2. Make terraform changes
nano terraform/main.tf

# 3. Validate and format
make validate && make format

# 4. Security scan
make security

# 5. Plan changes
make plan

# 6. Review plan output
terraform show tfplan | less

# 7. Commit changes
git add .
git commit -m "Add X resource to Terraform [skip ci]"

# 8. Push and create PR
git push origin feature/my-change
# Create PR on GitHub

# 9. Wait for GitHub Actions
# - GitHub runs: validate, fmt, security, plan
# - GitHub posts plan as PR comment

# 10. Review with team (Live Share for discussion)
Ctrl+Shift+P → "Live Share: Start collaboration session"

# 11. Merge PR
# GitHub Actions will apply

# 12. Verify deployment
terraform state list
terraform state show azurerm_resource_group.example

# 13. Later: Check for drift
make drift-check
# Or watch GitHub Actions drift detection job run at scheduled time
```

---

## Quick Links

- Terraform Docs: https://www.terraform.io/docs
- Azure Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Checkov: https://www.checkov.io/
- terraform-compliance: https://terraform-compliance.com/
- Azure CLI: https://learn.microsoft.com/en-us/cli/azure/
- AWS CLI: https://docs.aws.amazon.com/cli/

---

**Tips:**
- Pin this document in VSCode for quick reference
- Update with your team's common commands
- Add project-specific commands to Makefile
- Share with new team members for onboarding

Happy coding! 🚀
