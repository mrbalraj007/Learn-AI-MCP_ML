# 🚀 GitHub Codespaces DevContainer — Terraform & AWS CLI (No Docker)

> A simple step-by-step guide to set up a **Dev Container** in GitHub Codespaces with **Terraform** and **AWS CLI** using only `devcontainer.json` — no Dockerfile required.

---

## 📋 Table of Contents

- [🚀 GitHub Codespaces DevContainer — Terraform \& AWS CLI (No Docker)](#-github-codespaces-devcontainer--terraform--aws-cli-no-docker)
  - [📋 Table of Contents](#-table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Step 1 — Create a GitHub Repository](#step-1--create-a-github-repository)
  - [Step 2 — Launch GitHub Codespaces](#step-2--launch-github-codespaces)
    - [What each section does](#what-each-section-does)
  - [Step 5 — Rebuild the Container](#step-5--rebuild-the-container)
  - [Step 6 — Verify Terraform](#step-6--verify-terraform)
  - [Step 7 — Verify AWS CLI](#step-7--verify-aws-cli)
  - [Step 8 — Configure AWS Credentials](#step-8--configure-aws-credentials)
    - [Recommended — GitHub Codespaces Secrets](#recommended--github-codespaces-secrets)
    - [Alternative — aws configure (quick test)](#alternative--aws-configure-quick-test)
    - [Verify credentials are working](#verify-credentials-are-working)
  - [Folder Structure](#folder-structure)
  - [Troubleshooting](#troubleshooting)
  - [📚 References](#-references)

---

## Prerequisites

| Requirement | Details |
|---|---|
| GitHub Account | Free or paid — [github.com](https://github.com) |
| Codespaces Access | Free tier: 60 hrs/month |
| AWS Account | Needed for Step 8 credential setup |

---

## Step 1 — Create a GitHub Repository

1. Log in to [github.com](https://github.com)
2. Click the **"New"** button (top-left)
3. Enter a repository name, e.g. `tf-aws-codespace`
4. Tick **"Add a README file"**
5. Click **"Create repository"**

> 📸 **Screenshot — New Repository form:**
>
> ![Create Repo](https://docs.github.com/assets/cb-29762/mw-1440/images/help/repository/repo-create-global-nav-update.webp)

---

## Step 2 — Launch GitHub Codespaces

Inside your new repository:

1. Click the green **`<> Code`** button (top right)
2. Click the **"Codespaces"** tab
3. Click **"Create codespace on main"**

> 📸 **Screenshot — Codespaces tab inside the Code button:**
>
> ![alt text](image.png)

> ⏳ Wait ~1 minute for the default Codespace to load (VS Code in browser).

---

![alt text](image-1.png)

![alt text](image-2.png)

![alt text](image-3.png)

![alt text](image-4.png)

![alt text](image-5.png)

```sh
{
	"image": "mcr.microsoft.com/devcontainers/universal:2",
	"features": {
		"ghcr.io/devcontainers/features/aws-cli:1": {
			"verbose": true,
			"version": "latest"
		},
		"ghcr.io/devcontainers/features/terraform:1": {
			"version": "latest",
			"tflint": "latest",
			"terragrunt": "latest"
		}
	}
}
```

![alt text](image-6.png)

Rebuild

![alt text](image-7.png)
![alt text](image-8.png)

0 : <img width="945" height="526" alt="Image" src="https://github.com/user-attachments/assets/2e2e3164-2f63-4ded-9170-2316373c43c3" />
1: <img width="1281" height="271" alt="Image" src="https://github.com/user-attachments/assets/4d3a0153-7330-45aa-8912-4cb8eff44e86" />
2: <img width="1204" height="252" alt="Image" src="https://github.com/user-attachments/assets/8b55fcdb-8286-4dee-932e-f881055867c1" />
3: <img width="945" height="526" alt="Image" src="https://github.com/user-attachments/assets/5382b41c-dfa7-4833-93b3-a91193b7d415" />
4: <img width="945" height="526" alt="Image" src="https://github.com/user-attachments/assets/5e229162-3ca9-4220-9594-1794d90832aa" />
5: <img width="1182" height="192" alt="Image" src="https://github.com/user-attachments/assets/259cb875-67ac-491e-a917-c3ac9b1e9aee" />
6: <img width="1576" height="925" alt="Image" src="https://github.com/user-attachments/assets/c29ada15-4918-4ae6-ab09-bbabd1b30f85" />
7: <img width="1160" height="371" alt="Image" src="https://github.com/user-attachments/assets/aa2893cc-e2f2-4aef-ad36-38ccff708a52" />
8: <img width="1262" height="601" alt="Image" src="https://github.com/user-attachments/assets/393082e7-9b0d-45f9-8518-4567b8a3c4c5" />

codespace 60 hours/month, 2 hours a day

>devcontainer configuration file | terraform [terraform, tflint, Tfgrunt,devcontainers] /aws cli

> codespace:Rebuild Container

GitHub Codespaces is a sandbox environment as a container environment.

<!-- 
## Step 3 — Create the `.devcontainer` Folder

Once the Codespace is open, use the **terminal** (`` Ctrl+` ``) and run:

```bash
mkdir -p .devcontainer
```

> 📸 **Screenshot — Terminal in Codespace:**
>
> ```
> Open terminal with Ctrl+` (backtick)
> Type: mkdir -p .devcontainer
> Press Enter
> The Explorer panel (left sidebar) now shows the .devcontainer folder
> ```

Or via the Explorer panel:
- Right-click in the file tree → **"New Folder"** → type `.devcontainer`

---

## Step 4 — Create `devcontainer.json`

This single file does everything — **no Dockerfile needed**.

Create the file:

```bash
touch .devcontainer/devcontainer.json
```

Open it in the editor and paste:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "Terraform + AWS CLI",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/terraform:1": {
      "version": "latest"
    },
    "ghcr.io/devcontainers/features/aws-cli:1": {
      "version": "latest"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "hashicorp.terraform",
        "amazonwebservices.aws-toolkit-vscode"
      ]
    }
  },
  "postCreateCommand": "echo '✅ Done!' && terraform version && aws --version"
}
```

> 📸 **Screenshot — devcontainer.json open in VS Code editor:**
>
> ```
> Explorer panel → .devcontainer/devcontainer.json
> Editor shows the JSON content with "features" block listing
> terraform and aws-cli entries
> ``` -->

### What each section does

| Key | Purpose |
|---|---|
| `"image"` | Uses Microsoft's official Ubuntu base image — no custom Dockerfile |
| `"features" → terraform` | Installs Terraform via the official DevContainer feature |
| `"features" → aws-cli` | Installs AWS CLI v2 via the official DevContainer feature |
| `"extensions"` | Auto-installs HashiCorp Terraform + AWS Toolkit in VS Code |
| `"postCreateCommand"` | Runs once after build — confirms both tools are working |

---

## Step 5 — Rebuild the Container

After saving `devcontainer.json`:

1. Press **`Ctrl+Shift+P`** to open the Command Palette
2. Type **`rebuild`**
3. Select **"Dev Containers: Rebuild Container"**
4. Wait for the rebuild to finish (~3–5 minutes)

> 📸 **Screenshot — Command Palette with Rebuild option:**
>
> ```
> Ctrl+Shift+P opens the command palette at the top of the screen
> Type "rebuild" → list filters to show:
>   ▶ Dev Containers: Rebuild Container
> Click it → confirmation prompt → container rebuilds
> Build log appears in the terminal showing features being installed
> ```

> 💡 You may also see a notification banner:
> **"Dev container configuration file has changed."** → Click **"Rebuild"**

---

## Step 6 — Verify Terraform

Once the rebuild completes, open a terminal and run:

```bash
terraform version
```

**Expected output:**
```
Terraform v1.x.x
on linux_amd64
```

```bash
which terraform
# /usr/local/bin/terraform
```

> 📸 **Screenshot — terraform version in terminal:**
>
> ```
> Terminal panel → terraform version
> Output: Terraform v1.x.x on linux_amd64
> Also check VS Code Extensions panel (left sidebar):
>   HashiCorp Terraform extension showing as installed
> ```

---

## Step 7 — Verify AWS CLI

In the same terminal, run:

```bash
aws --version
```

**Expected output:**
```
aws-cli/2.x.x Python/3.x.x Linux/x86_64
```

```bash
which aws
# /usr/local/bin/aws
```

> 📸 **Screenshot — aws --version in terminal:**
>
> ```
> Terminal panel → aws --version
> Output: aws-cli/2.x.x Python/3.x.x Linux/...
> Also check VS Code Extensions panel:
>   AWS Toolkit extension showing as installed
> ```

---

## Step 8 — Configure AWS Credentials

> ⚠️ Never commit credentials into your repository.

### Recommended — GitHub Codespaces Secrets

1. Go to **GitHub → Settings → Codespaces**
2. Under **"Secrets"**, click **"New secret"**
3. Add each of these:

| Secret Name | Example Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtnFEMI/K7MDENG/...` |
| `AWS_DEFAULT_REGION` | `ap-southeast-2` |

> 📸 **Screenshot — GitHub Codespaces Secrets page:**
>
> ```
> github.com → Profile icon (top right) → Settings
> → Left sidebar → "Codespaces"
> → "Secrets" section → "New secret" button
> → Name field: AWS_ACCESS_KEY_ID
> → Value field: your key
> → Click "Add secret"
> ```

These are injected automatically as environment variables when your Codespace starts.

### Alternative — aws configure (quick test)

```bash
aws configure
```

```
AWS Access Key ID:     AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name:   ap-southeast-2
Default output format: json
```

### Verify credentials are working

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

## Folder Structure

Your final repo layout:

```
tf-aws-codespace/
│
├── .devcontainer/
│   └── devcontainer.json    ← Single config file — no Dockerfile needed
│
└── README.md
```

That's it — **one file** to get a fully configured Terraform + AWS CLI environment.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `terraform: command not found` | Rebuild container: `Ctrl+Shift+P` → "Rebuild Container" |
| `aws: command not found` | Same as above — check build log for feature install errors |
| `No valid credential sources` | Verify Codespaces Secrets are set; run `env \| grep AWS` to confirm |
| Rebuild takes too long | Normal on first build (~5 min); subsequent rebuilds are faster |
| Feature version error | Change `"version": "latest"` to a specific version e.g. `"1.7.0"` |

---

## 📚 References

| Resource | URL |
|---|---|
| Dev Container Features — Terraform | https://github.com/devcontainers/features/tree/main/src/terraform |
| Dev Container Features — AWS CLI | https://github.com/devcontainers/features/tree/main/src/aws-cli |
| GitHub Codespaces Docs | https://docs.github.com/en/codespaces |
| Codespaces Secrets Setup | https://docs.github.com/en/codespaces/managing-your-codespaces/managing-secrets-for-your-codespaces |

---
