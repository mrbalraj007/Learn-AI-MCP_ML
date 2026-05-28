# 🚀 GitHub Codespaces DevContainer Setup — Terraform & AWS CLI

> A step-by-step guide to create a fully configured **Dev Container** in GitHub Codespaces with **Terraform** and **AWS CLI** pre-installed and ready to use.

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1 — Create or Open a GitHub Repository](#step-1--create-or-open-a-github-repository)
- [Step 2 — Launch GitHub Codespaces](#step-2--launch-github-codespaces)
- [Step 3 — Create the `.devcontainer` Folder Structure](#step-3--create-the-devcontainer-folder-structure)
- [Step 4 — Create `devcontainer.json`](#step-4--create-devcontainerjson)
- [Step 5 — Create the `Dockerfile`](#step-5--create-the-dockerfile)
- [Step 6 — Rebuild the Container](#step-6--rebuild-the-container)
- [Step 7 — Verify Terraform Installation](#step-7--verify-terraform-installation)
- [Step 8 — Verify AWS CLI Installation](#step-8--verify-aws-cli-installation)
- [Step 9 — Configure AWS Credentials](#step-9--configure-aws-credentials)
- [Step 10 — Test with a Simple Terraform Plan](#step-10--test-with-a-simple-terraform-plan)
- [Folder Structure Summary](#folder-structure-summary)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

| Requirement | Details |
|---|---|
| GitHub Account | Free or paid — [github.com](https://github.com) |
| Codespaces Access | Available on Free tier (60 hrs/month) or paid plans |
| AWS Account | For credential configuration in Step 9 |
| Basic Git knowledge | Clone, commit, push |

> 💡 **Note:** GitHub Codespaces runs entirely in the browser — no local Docker or VS Code installation required.

---

## Step 1 — Create or Open a GitHub Repository

1. Log in to [github.com](https://github.com)
2. Click **"New"** or navigate to an existing repository
3. Name your repository (e.g., `terraform-aws-devcontainer`)
4. Select **Public** or **Private**
5. Check **"Add a README file"**
6. Click **"Create repository"**

> 📸 **Screenshot Reference:**
> ```
> GitHub Dashboard → Top-left green "New" button → Repository creation form
> → Fill name → Check "Add a README file" → Click "Create repository"
> ```

![GitHub New Repository](https://docs.github.com/assets/cb-29762/mw-1440/images/help/repository/repo-create-global-nav-update.webp)

---

## Step 2 — Launch GitHub Codespaces

Once inside your repository:

1. Click the green **`<> Code`** button (top right)
2. Select the **"Codespaces"** tab
3. Click **"Create codespace on main"**

> 📸 **Screenshot Reference:**
> ```
> Repository page → Green "Code" button → "Codespaces" tab
> → "Create codespace on main" button
> ```

![GitHub Codespaces Launch](https://docs.github.com/assets/cb-49500/mw-1440/images/help/codespaces/new-codespace-button.webp)

> ⏳ Wait 1–2 minutes for the default Codespace environment to load in your browser (VS Code interface).

---

## Step 3 — Create the `.devcontainer` Folder Structure

Inside the Codespace terminal (`` Ctrl+` `` to open), run:

```bash
mkdir -p .devcontainer
```

You need to create **two files** inside `.devcontainer/`:

```
.devcontainer/
├── devcontainer.json     ← Container configuration
└── Dockerfile            ← Custom image with Terraform + AWS CLI
```

> 📸 **Screenshot Reference:**
> ```
> Codespace VS Code UI → Terminal panel at bottom
> → Type: mkdir -p .devcontainer
> → Explorer sidebar (left) shows new ".devcontainer" folder
> ```

You can also create the folder via the **Explorer panel**:
- Click the **Explorer icon** (top-left sidebar)
- Right-click in the file tree → **"New Folder"** → type `.devcontainer`

---

## Step 4 — Create `devcontainer.json`

Inside `.devcontainer/`, create a file named **`devcontainer.json`**:

```bash
touch .devcontainer/devcontainer.json
```

Open the file and paste the following content:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "Terraform & AWS CLI DevContainer",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "hashicorp.terraform",
        "amazonwebservices.aws-toolkit-vscode",
        "ms-azuretools.vscode-docker",
        "redhat.vscode-yaml",
        "streetsidesoftware.code-spell-checker",
        "eamodio.gitlens"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "editor.formatOnSave": true,
        "[terraform]": {
          "editor.defaultFormatter": "hashicorp.terraform",
          "editor.formatOnSave": true
        }
      }
    }
  },
  "forwardPorts": [],
  "postCreateCommand": "terraform version && aws --version",
  "remoteUser": "vscode",
  "features": {}
}
```

> 📸 **Screenshot Reference:**
> ```
> VS Code Explorer → .devcontainer/devcontainer.json open in editor
> → JSON content visible with the extensions and settings blocks
> ```

**Key fields explained:**

| Field | Purpose |
|---|---|
| `build.dockerfile` | Points to our custom `Dockerfile` |
| `customizations.vscode.extensions` | Auto-installs Terraform, AWS Toolkit, GitLens extensions |
| `postCreateCommand` | Runs after container build — verifies both tools installed |
| `remoteUser` | Sets the non-root user inside the container |

---

## Step 5 — Create the `Dockerfile`

Inside `.devcontainer/`, create a file named **`Dockerfile`**:

```bash
touch .devcontainer/Dockerfile
```

Open the file and paste the following:

```dockerfile
# .devcontainer/Dockerfile
# Base image — Debian-based Ubuntu for broad compatibility
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# ─────────────────────────────────────────────
# Build Arguments — pin versions for reproducibility
# ─────────────────────────────────────────────
ARG TERRAFORM_VERSION=1.8.5
ARG AWSCLI_VERSION=2.17.0

# ─────────────────────────────────────────────
# System dependencies
# ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    gnupg \
    software-properties-common \
    lsb-release \
    git \
    jq \
    wget \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────
# Install Terraform
# ─────────────────────────────────────────────
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform=${TERRAFORM_VERSION}-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────
# Install AWS CLI v2
# ─────────────────────────────────────────────
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        AWS_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        AWS_ARCH="aarch64"; \
    fi && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o /tmp/awscliv2.zip \
    && unzip /tmp/awscliv2.zip -d /tmp/awscliv2 \
    && /tmp/awscliv2/aws/install \
    && rm -rf /tmp/awscliv2 /tmp/awscliv2.zip

# ─────────────────────────────────────────────
# Set working directory
# ─────────────────────────────────────────────
WORKDIR /workspace

# Verify installations at build time
RUN terraform version && aws --version

# Switch to non-root user (provided by base image)
USER vscode
```

> 📸 **Screenshot Reference:**
> ```
> VS Code Editor → .devcontainer/Dockerfile open
> → Dockerfile content showing FROM, ARG, RUN blocks for Terraform and AWS CLI
> ```

**Key sections explained:**

| Section | Details |
|---|---|
| `FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04` | Microsoft's official DevContainer base image |
| `ARG TERRAFORM_VERSION` | Pin exact Terraform version — update as needed |
| `ARG AWSCLI_VERSION` | Reference variable for AWS CLI version |
| HashiCorp APT install | Official HashiCorp APT repository with GPG signature verification |
| AWS CLI v2 install | Official AWS zip installer — handles both `x86_64` and `aarch64` arch |
| `USER vscode` | Drop to non-root user for security |

> 🔄 **To update versions**, simply change the `ARG` values and rebuild:
> ```bash
> # Check latest Terraform: https://developer.hashicorp.com/terraform/downloads
> # Check latest AWS CLI:    https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst
> ```

---

## Step 6 — Rebuild the Container

After saving both files, you need to **rebuild the Codespace container**:

### Option A — Command Palette (Recommended)

1. Press **`Ctrl+Shift+P`** (or `Cmd+Shift+P` on Mac) to open the Command Palette
2. Type: `Dev Containers: Rebuild Container`
3. Select **"Dev Containers: Rebuild Container"**
4. Click **OK** on the confirmation prompt

> 📸 **Screenshot Reference:**
> ```
> VS Code Command Palette open (top center of screen)
> → Search "Rebuild Container"
> → "Dev Containers: Rebuild Container" highlighted in dropdown
> ```

### Option B — Notification Banner

When Codespaces detects changes to `.devcontainer/`, a notification appears:

```
"Dev container configuration file has changed. Rebuild to apply changes."  [Rebuild]
```

Click **"Rebuild"**.

> ⏳ The rebuild takes **3–7 minutes** as Docker pulls the base image and installs Terraform + AWS CLI. You'll see build logs in the terminal.

---

## Step 7 — Verify Terraform Installation

Once the rebuild is complete and the terminal is available, run:

```bash
terraform version
```

**Expected output:**
```
Terraform v1.8.5
on linux_amd64
```

Also verify the Terraform VS Code extension is active:
```bash
# Check Terraform binary location
which terraform

# Output: /usr/bin/terraform
```

> 📸 **Screenshot Reference:**
> ```
> Codespace terminal → command: terraform version
> → Output showing "Terraform v1.8.x on linux_amd64"
> → VS Code Extensions panel (left sidebar) showing HashiCorp Terraform extension installed
> ```

---

## Step 8 — Verify AWS CLI Installation

In the Codespace terminal, run:

```bash
aws --version
```

**Expected output:**
```
aws-cli/2.17.0 Python/3.11.x Linux/5.x.x exe/x86_64
```

Check the binary location:
```bash
which aws

# Output: /usr/local/bin/aws
```

> 📸 **Screenshot Reference:**
> ```
> Codespace terminal → command: aws --version
> → Output showing "aws-cli/2.x.x Python/3.x.x Linux/..."
> ```

---

## Step 9 — Configure AWS Credentials

> ⚠️ **Security Warning:** Never hard-code credentials in your repository files. Use GitHub Secrets or environment variables.

### Method A — GitHub Codespaces Secrets (Recommended for Codespaces)

1. Go to **GitHub → Settings → Codespaces** (or Repository Settings → Secrets → Codespaces)
2. Click **"New secret"**
3. Add the following secrets:

| Secret Name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM secret key |
| `AWS_DEFAULT_REGION` | e.g., `ap-southeast-2` (Sydney) |

> 📸 **Screenshot Reference:**
> ```
> GitHub → Your profile photo → Settings
> → "Codespaces" in left sidebar
> → "Secrets" section → "New secret" button
> → Name: AWS_ACCESS_KEY_ID, Value: AKIA...
> ```

These secrets are automatically available as environment variables in your Codespace.

### Method B — `aws configure` (Interactive)

Inside the Codespace terminal:

```bash
aws configure
```

Follow the prompts:
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: ap-southeast-2
Default output format [None]: json
```

> 📸 **Screenshot Reference:**
> ```
> Codespace terminal → command: aws configure
> → Interactive prompts for Access Key, Secret Key, Region, Output format
> ```

### Verify AWS Credentials

```bash
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

---

## Step 10 — Test with a Simple Terraform Plan

Create a quick test to confirm everything works end-to-end:

```bash
# Create a test directory
mkdir -p /workspace/test-tf && cd /workspace/test-tf
```

Create a minimal `main.tf`:

```bash
cat > main.tf <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-southeast-2"
}

# Data source only — read-only, no infrastructure created
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
EOF
```

Run Terraform:

```bash
# Initialise providers
terraform init

# Format check
terraform fmt -check

# Validate syntax
terraform validate

# Plan (read-only — shows what would change)
terraform plan
```

**Expected output after `terraform plan`:**
```
Terraform will perform the following actions:
  # No changes. Your infrastructure matches the configuration.

Changes to Outputs:
  + account_id = "123456789012"
  + caller_arn = "arn:aws:iam::123456789012:user/your-username"

Plan: 0 to add, 0 to change, 0 to destroy.
```

> 📸 **Screenshot Reference:**
> ```
> Codespace terminal → terraform init (providers downloading)
> → terraform validate (Success! The configuration is valid.)
> → terraform plan (showing outputs, 0 to add/change/destroy)
> ```

> ✅ **Success!** Your DevContainer is fully operational with Terraform and AWS CLI.

---

## Folder Structure Summary

Your final repository structure should look like:

```
terraform-aws-devcontainer/
│
├── .devcontainer/
│   ├── devcontainer.json       ← DevContainer config (extensions, settings, post-create)
│   └── Dockerfile              ← Custom image: Ubuntu 22.04 + Terraform + AWS CLI v2
│
├── test-tf/
│   └── main.tf                 ← Quick smoke test (optional, can be deleted)
│
└── README.md                   ← This file
```

---

## Troubleshooting

### ❌ `terraform: command not found` after rebuild

- Check the Dockerfile `RUN` block for Terraform completed without errors
- Open the build log: **Command Palette → "Dev Containers: Show Log"**
- Ensure `TERRAFORM_VERSION` matches a valid release: [releases.hashicorp.com](https://releases.hashicorp.com/terraform/)

### ❌ `aws: command not found` after rebuild

- Confirm the AWS CLI install block in Dockerfile ran cleanly in build logs
- Test manually in terminal:
  ```bash
  ls -la /usr/local/bin/aws
  ```

### ❌ `Error: No valid credential sources found`

- Confirm GitHub Codespaces secrets are set correctly (Steps in Step 9)
- Restart the Codespace: **Command Palette → "Codespaces: Stop Current Codespace"**, then reopen
- Verify with: `env | grep AWS`

### ❌ Container rebuild fails with `apt-get` errors

- HashiCorp GPG key or APT repo may be temporarily unavailable
- Try pinning an older Terraform version in `ARG TERRAFORM_VERSION`
- Retry rebuild after a few minutes

### ❌ Codespace takes too long to build

- Normal first-build time: 5–10 minutes
- Subsequent rebuilds (if Docker layer cache is warm): 1–3 minutes
- Pre-build your Codespace: **Repository Settings → Codespaces → "Set up prebuild"**

---

## 📚 References

| Resource | URL |
|---|---|
| GitHub Codespaces Docs | https://docs.github.com/en/codespaces |
| Dev Containers Specification | https://containers.dev |
| Terraform Downloads | https://developer.hashicorp.com/terraform/downloads |
| AWS CLI v2 Install Guide | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| HashiCorp Terraform VS Code Extension | https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform |
| AWS Toolkit for VS Code | https://marketplace.visualstudio.com/items?itemName=AmazonWebServices.aws-toolkit-vscode |

---

> 🛠️ **Author:** Infrastructure & Cloud Engineering Guide
> 📅 **Last Updated:** May 2026
> 🏷️ **Tags:** `terraform` `aws-cli` `devcontainer` `github-codespaces` `iac` `devops`
