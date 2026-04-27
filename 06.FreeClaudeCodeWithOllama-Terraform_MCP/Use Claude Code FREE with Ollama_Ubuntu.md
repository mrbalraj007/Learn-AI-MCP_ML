# STOP Paying for AI! Use Claude Code FREE with Ollama 🚀

A **step-by-step technical guide** to building AI-powered websites, MVPs, and applications using **Claude Code**, **Ollama**, and **VS Code** without any paid subscription.

---



---

## 🧠 System Architecture (High-Level)

| Component | Role |
|--------|------|
| VS Code | Main IDE where development happens |
| Node.js | Required runtime for Claude Code |
| Claude Code | AI coding agent |
| Ollama | Bridge between Claude Code and AI models |
| Minimax M2.7 | Cloud-hosted AI model (AI brain) |

> Claude Code acts as the **agent**, Minimax as the **brain**, and Ollama as the **bridge**.

---

## ✅ Prerequisites

- Download ollama
- Download Gitbash
- NPM package
- Windows / macOS / Linux system OS
- Internet connection 
- Basic familiarity with VS Code & terminal usage

---

## 🛠 Step-by-Step Setup Guide

### Step 1: Install Visual Studio Code

1. Visit the official [VS Code website](https://code.visualstudio.com/download)
2. Download for your operating system
3. Install and open VS Code

**Purpose:** Code editor for all AI-generated files

---

### Step 2: Install Node.js

Claude Code requires Node.js.

1. Go to the official [Node.js](https://nodejs.org/en/download) website
2. Download the installer (MSI for Windows)
3. Install Node.js
4. Verify installation:

```bash
# Download and install Chocolatey:
powershell -c "irm https://community.chocolatey.org/install.ps1|iex"

# Download and install Node.js:
choco install nodejs --version="24.15.0"

# Verify the Node.js version:
node -v # Should print "v24.15.0".

# Verify npm version:
npm -v # Should print "11.12.1".
```
<details>
<summary><b>Verify Chocolatey exists</b></summary><br>

**Step 1 — Verify Chocolatey exists**

Run this in PowerShell (Admin):
```bash
Test-Path C:\ProgramData\chocolatey\bin\choco.exe
```
**Expected result:**
```PowerShell
True
```
✅ This confirms Chocolatey is installed correctly.


**Step 2 — Add Chocolatey to PATH (Permanent Fix)**
🔹 Add it for ALL users (recommended)
Still in PowerShell (Admin):
```PowerShell
$env:Path += ";C:\ProgramData\chocolatey\bin"
[Environment]::SetEnvironmentVariable(
  "Path",
  [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\ProgramData\chocolatey\bin",
  "Machine"
)
```
✅ This permanently fixes Chocolatey for:

- PowerShell
- Command Prompt
- Git Bash
- Any terminal


**Step 3 — Restart PowerShell (IMPORTANT)**

Close all PowerShell windows

Open a new PowerShell (Admin)

Then run:
```PowerShell
choco -v
```
You should see something like:
```PowerShell
2.x.x
```
✅ Chocolatey is now working.

**Step 4 — Install Node.js (Correctly)**
Now run:
```PowerShell
choco install nodejs --version="24.15.0" -y
```
Wait for it to finish.

**Step 5 — Verify Node & npm**
Still in PowerShell:
```PowerShell
node -v
npm -v
```
Expected:
```PowerShell
v24.15.0
11.12.1
```

**Step 6 — Make Node work in Git Bash**

Close ALL Git Bash windows
Reopen Git Bash
Run:
If Git Bash still doesn’t see it, run once:
```Shell
echo 'export PATH="$PATH:/c/Program Files/nodejs"' >> ~/.bashrc
source ~/.bashrc
```
</details>

<details>

<summary><b>Verify Node exists</b></summary><br>

**Step 1 — Locate where Node is actually installed**
Run this in PowerShell (Admin):
```Shell
Get-ChildItem "C:\Program Files" -Directory | Where-Object Name -Match "node"
```
One of these should exist:
```shell
C:\Program Files\nodejs
C:\Program Files (x86)\nodejs
```
Now check directly:
```Shell
Test-Path "C:\Program Files\nodejs\node.exe"
Test-Path "C:\Program Files (x86)\nodejs\node.exe"
```
✅ One of these will return True.

**Step 2 — Temporarily test Node (no PATH change yet)**
Replace the path that exists and run:
```Shell
& "C:\Program Files\nodejs\node.exe" -v
```
(or x86 path if that’s the one)

✅ If this prints v24.15.0, Node itself is perfectly fine.

**Step 3 — Permanently fix PATH (SYSTEM‑WIDE)**
This is the real fix.
Run exactly this in PowerShell (Admin):
```shell
[System.Environment]::SetEnvironmentVariable(
  "Path",
  [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\nodejs",
  "Machine"
)
```
This adds Node to the machine PATH, not just your user.

**Step 4 — Restart PowerShell (MANDATORY)**
- Close ALL PowerShell windows
- Open new PowerShell (Admin)

Then run:
```Shell
node -v
npm -v
```
</details>

<details>
<summary><b>If above both doesn't fix then run it</b></summary><br>

**Check what PATH PowerShell is ACTUALLY using**
Run:
```Shell
$env:Path -split ';'
```
Now look closely:

Do you see C:\Program Files\nodejs?

✅ YES → PATH is present but overridden
❌ NO → Machine PATH is not being loaded

**Step 3 — Check Machine vs User PATH (this is the key)**
Run both:
```Shell
[System.Environment]::GetEnvironmentVariable("Path", "Machine")
```
```Shell
[System.Environment]::GetEnvironmentVariable("Path", "User")
```
⚠️ Important discovery (very likely)

On many Windows Server systems:

User PATH overrides Machine PATH

If User PATH exists and is malformed → Machine PATH is ignored


**Step 4 — HARD FIX (works every time)**

🔥 We will rebuild User PATH to INCLUDE Machine PATH

Run this in PowerShell (Admin):

```Shell
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not $userPath.Contains("C:\Program Files\nodejs")) {
    [System.Environment]::SetEnvironmentVariable(
        "Path",
        $userPath + ";" + $machinePath,
        "User"
    )
}
```
✅ This forces:

User PATH ✅
Machine PATH ✅
Node PATH ✅


**Step 5 — HARD RESTART REQUIRED**

Environment variables will not refresh properly until:

✅ Do ONE of the following:

Sign out of the Administrator account and sign back in

OR

Reboot the machine (best option)

This is mandatory on Windows Server.
</details>

---

### Step 3: Install Ollama

1. Visit https://ollama.com
2. [Download Ollama for your OS](https://ollama.com/download/windows)
3. Install and launch the application
<img width="1306" height="723" alt="Image" src="https://github.com/user-attachments/assets/6d0e8ea5-59ae-4631-a042-fab97eb12307" />


**Purpose:** Connects Claude Code with AI models

---

### Step 4: Create an Ollama Account

1. Open Ollama
2. Go to Settings
3. Click **Sign In**
   <img width="809" height="630" alt="Image" src="https://github.com/user-attachments/assets/411a5485-d4a7-4e0f-93cd-55bfc5fa2d39" />
   <img width="809" height="630" alt="Image" src="https://github.com/user-attachments/assets/b8360d72-2def-460b-bed9-5874e0194728" />
4. Complete login in browser

✅ Ollama accounts are **free**


---

### Step 5: Install Claude Code CLI

Install [Claude Code](https://code.claude.com/docs/en/quickstart) globally using npm:

```bash
npm install -g @anthropic-ai/claude-code
```
<img width="972" height="836" alt="Image" src="https://github.com/user-attachments/assets/449c9f63-cc2b-4dc8-bbfd-5c4b0c395e32" />
---

### Step 6: Verify Claude Code Installation

```bash
claude --version
```
<img width="972" height="836" alt="Image" src="https://github.com/user-attachments/assets/c580707f-663d-458f-88ba-99f218589f57" />
If installed correctly, the version number will be displayed.

---

### Step 7: Install Claude Code VS Code Extension

1. Open VS Code
2. Go to **Extensions**
3. Search for **Claude Code**
4. Install the official extension
<img width="972" height="836" alt="Image" src="https://github.com/user-attachments/assets/3f22a227-1113-4d11-b89c-f294e89bf2fa" />
---

## 🔗 Connecting Claude Code with Ollama

### Step 8: Select AI Model (Minimax M2.7)

- Open Ollama Dashboard
- Navigate to **Models**
- Select **Minimax M2.7**
<img width="1249" height="556" alt="Image" src="https://github.com/user-attachments/assets/6977e563-a128-4053-b2f2-81ce544da527" />
- Copy the provided launch command

```sh
ollama launch claude --model minimax-m2.7:cloud
```
<img width="1249" height="556" alt="Image" src="https://github.com/user-attachments/assets/8ce9fde2-7927-4405-a444-3a00973dd286" />
✅ Model is cloud-hosted (no GPU or storage required)

---

### Step 9: Launch Claude Code with Ollama

In VS Code terminal:

```bash
ollama launch claude --model minimax-m2.7:cloud

# Breaking it down:
✓ # ollama = starts the Ollama bridge
✓ # launch = auto-setup command (no config needed)
✓ # claude = tells it to launch Claude Code
✓ # --model = specifies which AI brain to use
✓ # minimax-m2.7:cloud = powerful AI model on Ollama's servers
```
This command:
- Starts Ollama bridge
- Launches Claude Code agent
- Connects Minimax AI model

<details><summary><b>Troubleshooting</b></summary><br>
I am getting below error message while launching Claude code.

<img width="1249" height="556" alt="Image" src="https://github.com/user-attachments/assets/ca93b805-8129-44ba-ba18-4a0da119b538" />

fix:

Install the gitbash and relaunch VS Code editor
<img width="1249" height="838" alt="Image" src="https://github.com/user-attachments/assets/1cda8625-c6fd-4d20-a10b-f2f62a2ba3ca" />
</details>

Now, it's fully available
<img width="1514" height="838" alt="Image" src="https://github.com/user-attachments/assets/920d2772-e152-4d40-8de3-26842b069c1c" />
---

## 🚀 Example: Building a Landing Page with AI

### Sample Prompt

```
Create a modern dark-themed landing page for "Code Unwind".
It teaches AI, Data Science, and Coding.
Use a dark background with blue and green highlights.
Include:
- Hero section with headline
- Signup button
- Navigation bar
- Footer section
- Smooth background animations
```

### What Claude Code Does Automatically

- Creates project structure
- Generates HTML, CSS, and JavaScript
- Adds animations and styling
- Makes layout responsive

✅ No manual coding required

---

## 🎯 Prompting Best Practices

### ❌ Weak Prompt
```
Make it better
```

### ✅ Strong Prompt
```
Improve the hero section typography
Fix mobile menu closing issue
Add gradient background animation
```

> The more specific the prompt, the better the output

---

## ⭐ Key Highlights

- 100% free Claude Code usage
- No paid AI subscriptions
- Cloud AI brain (Minimax M2.7)
- Minimal system requirements
- Full VS Code integration
- Ideal for MVPs & rapid prototyping

---

## ✅ Advantages of This Setup

### 1. Zero Cost AI Coding
No monthly payments or API charges

### 2. No High-End Hardware Needed
Runs on low-end laptops

### 3. Faster Development
Build projects in minutes

### 4. Real AI Agent Behavior
Claude edits files, fixes bugs, and adds features

### 5. Beginner Friendly
No deep coding knowledge required

---

## 👥 Who Should Use This?

- Beginners learning web development
- Indie hackers & startup founders
- Students exploring AI tools
- Freelancers building landing pages
- Developers prototyping ideas quickly

---



🚀 Build smarter. Build faster. Build FREE.




```sh
curl -fsSL https://ollama.com/install.sh | sh
```


<!-- 

# Install Docker

Step 1 – Install Docker (if not installed)
```Shell
sudo apt update
sudo apt install -y ca-certificates curl gnupg
```
```Shell
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```
```shell
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
 https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
```Shell
sudo apt updatesudo apt install -y docker-ce docker-ce-cli containerd.ioShow more lines
```
Verify:
```Shell
docker --version
```

**Step 2 – (Optional but Recommended) Allow non-root Docker**
```Shell
sudo usermod -aG docker $USER
newgrp docker
```

**Step 3 – Run Terraform MCP Server (STDIO mode)**
This is the default and safest mode, designed for local MCP clients (VS Code, Claude Desktop).
Shelldocker run -i --rm hashicorp/terraform-mcp-serverShow more lines
✅ If you see the server waiting for JSON‑RPC input, it is running correctly. -->

# Claude Code Install
**Recommended Method: Native Installer (No Node.js needed)**
This is the official, preferred approach for Ubuntu and is what Anthropic recommends in 2025–2026. It installs Claude Code into your home directory and auto‑updates safely. [code.claude.com], [morphllm.com]

**Step 1: Update your system**
```Shell
sudo apt update
```

**Step 2: Install curl (if not already installed)**
```Shell
sudo apt install -y curl
```

Desktop Ubuntu usually has curl already, but server/minimal images often don’t.


**Step 3: Run the Claude Code installer**
```Shell
curl -fsSL https://claude.ai/install.sh | bash
```
```sh
root@dc-ops:~# curl -fsSL https://claude.ai/install.sh | bash
Setting up Claude Code...

✔ Claude Code successfully installed!

  Version: 2.1.119

  Location: ~/.local/bin/claude


  Next: Run claude --help to get started

⚠ Setup notes:
  ● Native installation exists but ~/.local/bin is not in your PATH. Run:

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc


✅ Installation complete!

root@dc-ops:~# echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
root@dc-ops:~# claude --version
2.1.119 (Claude Code)
root@dc-ops:~#
```

What this does:
```sh
Installs the claude binary to ~/.local/bin/claude
Stores versions under ~/.local/share/claude/
Adds ~/.local/bin to your PATH (if needed)
Enables automatic background updates
```
⚠ Do not use sudo for this command. It must be installed as your normal user.

**Step 4: Verify installation**
```Shell
claude --version
```
If you see a version number, installation succeeded ✅.

If claude: command not found, fix your PATH:
```Shell
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

**Step 5: Run diagnostics (recommended)**
```Shell
claude doctor
```
This checks network access, binaries, and environment setup.

**2️⃣ Pull a Coding‑Capable Model**
Claude Code needs:

Function calling
Tool execution
Large context (64k+ preferred)

**✅ Recommended starting models**
```Shell
ollama pull qwen3.5:cloud
```

Other strong options:

- glm-5:cloud
- kimi-k2.5:cloud
- minimax-m2.7:cloud

(Local‑only alternatives like qwen2.5-coder work, but tool use may be weaker). [docs.ollama.com]
List installed models:
```Shell
ollama list
```

**3️⃣ One‑Command Launch (Easiest Way)**
This is the recommended and cleanest method.
```Shell
ollama launch claude
```

- Ollama sets all required environment variables
- Claude Code is launched
- Model picker appears
- Claude Code now talks to Ollama, not Anthropic

➡ Choose your model (qwen3.5:cloud, etc.)
Done.
You are now using Claude Code with Ollama

**(Optional) Run with a Fixed Model**
```Shell
ollama launch claude --model qwen3.5:cloud
```
*For non‑interactive / CI mode:*
```Shell
ollama launch claude --model qwen3.5:cloud --yes -- -p "explain this repo"
```

# Install VS Code

**Recommended Method: Microsoft APT Repository (Best for updates)**
This installs VS Code directly from Microsoft and keeps it automatically updated.
**1️⃣ Update system and install requirements**
```Shell
sudo apt update
sudo apt install -y
```
**2️⃣ Import Microsoft’s GPG key**
```Shell
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
rm microsoft.gpg 
```

**3️⃣ Add the VS Code repository**
```shell
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
```
**4️⃣ Install VS Code**
```Shell
sudo apt updatesudo apt install -y code
```

5️⃣ Launch VS Code
```Shell
code
```

<!-- # Install Terraform

Recommended: Install Terraform via HashiCorp APT Repository
This works unchanged on both Ubuntu 22.04 and 24.04.
1️⃣ Update system and install prerequisites
```Shell
sudo apt update
sudo apt install -y gnupg software-properties-common curl

```
 [developer....hicorp.com]

2️⃣ Add HashiCorp’s GPG key
```Shell
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```
[Install Terraform](https://developer.hashicorp.com/terraform/install)

3️⃣ Add the official HashiCorp repository  (This automatically 
detects **jammy** or **noble**)


### 3️⃣ Add the official HashiCorp repository  
(This automatically detects **jammy** or **noble**)
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
```



### 4️⃣ Install Terraform
```bash
sudo apt update
sudo apt install terraform
``` -->
<!-- 
### 5️⃣ Verify installation
```bash
terraform -version
``` -->


when run the claude then run it below
```sh
Can you add my mcp server for terraform it should run a docker container locally 

{
  "mcpServers": {
    "servers": {
      "terraform": {
        "command": "docker",
        "args": [
          "run",
          "-i",
          "--rm",
          "-e", "TFE_ADDRESS=<<TFE_ADDRESS_HERE>>",
          "-e", "TFE_TOKEN=<<TFE_TOKEN_HERE>>",
          "hashicorp/terraform-mcp-server"
        ]
      }
    }
  }
}

and my token is
  xxxxxxxxxxxxxxxxxxxxxxxx and were using app.terraform.io.

```

docker pull hashicorp/terraform-mcp-server

```bash
claude mcp add terraform -- \
  docker run -i --rm \
  -e TFE_ADDRESS=https://app.terraform.io \
  -e TFE_TOKEN=******** \
  hashicorp/terraform-mcp-server
```
```bash
export TFE_TOKEN=xxxxx
export TFE_ADDRESS=https://app.terraform.io

claude mcp add -s user terraform \
  -e TFE_ADDRESS
```
<!-- aws configure list
aws configure list --profile my-profile
aws sts get-caller-identity -->

and run the terraform command and it will create for you.
