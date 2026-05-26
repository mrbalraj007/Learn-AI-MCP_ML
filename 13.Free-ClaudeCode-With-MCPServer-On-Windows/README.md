


---

## What We're Actually Building

Before jumping into commands, here's the architecture so nothing feels like magic:

```
Your Terminal (Claude Code CLI)
        ↓  ANTHROPIC_BASE_URL=http://localhost:8082
Local NVIDIA NIM Proxy Server  (Python / uvicorn)
        ↓  Translates Anthropic API format → NIM API format
NVIDIA NIM Cloud  (DeepSeek V4 Pro or similar)
        ↓  Response
Back to Claude Code
```

Claude Code thinks it's talking to Anthropic. The proxy quietly translates everything. Your code never leaves your network until it hits NVIDIA's endpoint.

**Tech stack involved:**
- `Node.js` — Claude Code CLI runtime requirement
- `npm` — Package manager for the install
- `uv` — Fast Python package/environment manager (from Astral)
- `Python 3.14` — Proxy server runtime
- `Go` — Required to build the Terraform MCP server binary
- `Git` — Clone the proxy repo
- `Terraform` — For the MCP integration
- `NVIDIA NIM API` — The free model endpoint
- `DeepSeek V4 Pro` — The model doing the actual work
- `uvicorn` — ASGI server that runs the local proxy

Let's go.

---

## Prerequisites Checklist

Before starting, confirm you have these available (or follow the steps below to install them):

- [ ] Node.js v16+ (v20+ recommended)
- [ ] npm
- [ ] Go
- [ ] Git
- [ ] Terraform
- [ ] uv (Python environment manager)

---

## Step 1 — Get Node.js Working

Claude Code is a Node.js application. There's no getting around this one.

```bash
# Check if you already have it
node --version   # Should show v16.0.0 or higher
npm --version
```

If you're on Windows and it's not installed yet, the cleanest path is through Chocolatey:

```powershell
# First — fix execution policy so installs don't fail
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Chocolatey
powershell -c "irm https://community.chocolatey.org/install.ps1 | iex"

# Install Node.js
choco install nodejs --version="24.15.0"

# Verify
node -v    # v24.15.0
npm -v     # 11.12.1
```

### Common issue: Node installed but terminal can't find it

This is a PATH problem. Run this to permanently fix it:

```powershell
[System.Environment]::SetEnvironmentVariable(
  "Path",
  [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\nodejs",
  "Machine"
)
```

Close and reopen PowerShell. That's it.

<details>
<summary>Still not working? Try this nuclear option for PATH</summary>

```powershell
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

After this, sign out and back in (or reboot if you're on Windows Server). Machine PATH and User PATH need a full session restart to merge properly.

</details>

---

## Step 2 — Install uv (Python Environment Manager)

`uv` is from the Astral team — same people behind Ruff. It's dramatically faster than pip and handles Python version management on its own. We need it to run the proxy server.

```powershell
# Open PowerShell as Administrator, then:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install uv
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

You'll see output like:

```
downloading uv 0.11.16 (x86_64-pc-windows-msvc)
installing to C:\Users\Administrator\.local\bin
everything's installed!
```

Now add it to your current session's PATH:

```powershell
$env:Path = "C:\Users\Administrator\.local\bin;$env:Path"
```

Close and reopen PowerShell, then verify:

```powershell
uv --version    # uv 0.x.x
```

### Install Python 3.14 via uv

```powershell
uv python install 3.14

# Verify
uv python list                          # Shows installed versions
uv run --python 3.14 python --version   # Python 3.14.x
```

---

## Step 3 — Install Claude Code CLI

This is the main CLI tool. Two ways to install depending on your shell:

**PowerShell (Admin):**
```powershell
irm https://claude.ai/install.ps1 | iex
```

**Windows CMD:**
```cmd
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

> **Quick tip:** If you see `The token '&&' is not a valid statement separator` — you're in PowerShell, not CMD. If you see `'irm' is not recognized` — you're in CMD, not PowerShell. Your prompt shows `PS C:\` in PowerShell.

After install, add it to your system PATH:

```powershell
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = "$path;C:\Users\Administrator\.local\bin"
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
```

Reopen the terminal, then:

```bash
claude --version
```

If a version number prints — you're good.

---

## Step 4 — Install the Claude Code VS Code Extension

If you use VS Code:

1. Open the Extensions panel (`Ctrl+Shift+X`)
2. Search **Claude Code**
3. Install the official extension

That's literally it. The extension picks up the CLI automatically.

---

## Step 5 — Set Up the NVIDIA NIM Proxy

This is where it gets interesting.

```bash
# Clone the proxy repo (Linux/Mac)
git clone https://github.com/Alishahryar1/free-claude-code.git nvidia-nim
cd nvidia-nim

# Create your config file
cp .env.example .env
```

Now open `.env` in your editor:

```bash
code .    # Opens in VS Code
```

You'll see two fields. Fill them in:

```env
NVIDIA_NIM_API_KEY=your_api_key_here
NVIDIA_NIM_MODEL=nvidia/deepseek-v4-0709-pro
```

The `MODEL` line in the file will look like:

```env
MODEL="nvidia_nim/deepseek-ai/deepseek-v4-pro"
```

### Getting Your NVIDIA NIM API Key

1. Go to [https://build.nvidia.com](https://build.nvidia.com)
2. Sign up and verify your account with a phone number
3. Click **Generate API Key**
4. Name it something like `claude-code`, set expiry to **Never Expire**
5. Copy the key into `.env`

### Finding the Right Model Name

1. On the NIM site, click **Models**
2. Pick a model (DeepSeek V4 Pro is solid)
3. Click **View Code**
4. Copy the model string (e.g. `deepseek-ai/deepseek-v4-0709-pro`)

To swap models from the command line:

```bash
sed -i 's|MODEL="nvidia_nim/nvidia/nemotron-3-super-120b-a12b"|MODEL="nvidia_nim/deepseek-ai/deepseek-v4-pro"|' .env
```

---

## Step 6 — Start the Proxy Server

From inside your `nvidia-nim` directory:

```bash
uv run uvicorn server:app --host 0.0.0.0 --port 8082
```

First run will download a few packages. After that you'll see the uvicorn startup message confirming the server is listening on port 8082.

**Leave this terminal window open.** The proxy needs to stay running while you use Claude Code.

---

## Step 7 — Install Go and Build the Terraform MCP Server

This step adds Terraform intelligence directly inside Claude Code through the Model Context Protocol (MCP). It's optional but genuinely useful if you work with Terraform daily.

### 7a — Get Go

```powershell
go version
```

Missing? Download from [https://go.dev/dl/](https://go.dev/dl/) (grab the `.msi` for Windows), install, reopen PowerShell.

### 7b — Build the Terraform MCP Server

```powershell
# Clone and build
git clone https://github.com/hashicorp/terraform-mcp-server.git
cd terraform-mcp-server

go build -o terraform-mcp-server.exe ./cmd/terraform-mcp-server

# Move to a permanent home
mkdir C:\tools\terraform-mcp-server
Move-Item terraform-mcp-server.exe C:\tools\terraform-mcp-server\

# Quick sanity check
C:\tools\terraform-mcp-server\terraform-mcp-server.exe --help
```

---

## Step 8 — Wire Up the MCP Server in Claude Code

Edit `~/.claude.json` directly:

```json
{
  "mcpServers": {
    "terraform": {
      "command": "C:\\tools\\terraform-mcp-server\\terraform-mcp-server.exe",
      "args": ["stdio"]
    }
  }
}
```

Or use the CLI shortcut:

```powershell
claude mcp add terraform -s user -- "C:\tools\terraform-mcp-server\terraform-mcp-server.exe" stdio
```

No restart needed. Config is picked up fresh each session.

---

## Step 9 — Launch Claude Code Against NVIDIA NIM

Navigate to your project folder, then run:

```bash
cd ~/your-project-folder

ANTHROPIC_AUTH_TOKEN="freecc" ANTHROPIC_BASE_URL="http://localhost:8082" claude
```

Choose **Dark Mode** when prompted (personal preference but it looks better), press Enter, and Claude Code will start up connected to your local proxy.

Verify the connection:

```
/status
```

You should see the `localhost:8082` URL confirming the NIM endpoint is active.

---

## Step 10 — Verify the Terraform MCP is Loaded

Create a quick test project:

```bash
mkdir Terraform_Demo
cd Terraform_Demo
```

Inside Claude Code CLI:

```
claude mcp list
```

`terraform` should appear in the connected servers list.

### Test prompts to try right away:

```
Validate the Terraform code in the current directory
Run a terraform plan and summarise what will change
List all providers used in this Terraform configuration
Check for any drift in the resources defined here
```

The MCP server runs actual Terraform commands in your working directory and feeds the results back into Claude's context. It's genuinely impressive once you see it in action.

---

## Full Setup Recap

| Step | What You're Doing | Tool |
|------|-------------------|------|
| 1 | Install Node.js runtime | `choco` / installer |
| 2 | Install Python env manager | `uv` |
| 3 | Install Claude Code CLI | `curl` / `irm` |
| 4 | Install VS Code extension | VS Code Marketplace |
| 5 | Clone & configure NIM proxy | `git`, `.env` |
| 6 | Start the local proxy server | `uvicorn` |
| 7 | Build Terraform MCP binary | `go build` |
| 8 | Register MCP with Claude Code | `~/.claude.json` |
| 9 | Launch Claude Code → NIM | env vars + `claude` |
| 10 | Verify Terraform MCP works | `mcp list` + test prompts |

---



---
<!-- 
*Built and tested on Windows Server 2025 with Git Bash and PowerShell. The proxy and MCP server work equally well on Ubuntu/macOS — just substitute the Windows-specific PATH commands with their shell equivalents.*

---

**Tags:** `#claudecode` `#ai` `#devops` `#terraform` `#nvidia` `#llm` `#fretools` `#developer` `#vscode` `#mcp` -->
