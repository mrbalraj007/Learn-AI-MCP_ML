# Claude Code — Free & Unlimited with NVIDIA NIM API (No Ollama, No GPU Required)

> **Platform Support:** macOS · Linux · Windows (via WSL2)  
> **Last Updated:** May 2026  
> **Author:** Technical Documentation

---

## Table of Contents

- [Claude Code — Free \& Unlimited with NVIDIA NIM API (No Ollama, No GPU Required)](#claude-code--free--unlimited-with-nvidia-nim-api-no-ollama-no-gpu-required)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Why This Setup Exists](#why-this-setup-exists)
  - [Tools \& Technologies Used](#tools--technologies-used)
  - [Key Points at a Glance](#key-points-at-a-glance)
  - [Prerequisites](#prerequisites)
  - [Setup Guide — macOS / Linux](#setup-guide--macos--linux)
    - [Step 1 — Install UV](#step-1--install-uv)
    - [Step 2 — Install Python 3.14 via UV](#step-2--install-python-314-via-uv)
    - [Step 3 — Download the NVIDIA NIM Proxy Folder](#step-3--download-the-nvidia-nim-proxy-folder)
    - [Step 4 — Create Your `.env` File](#step-4--create-your-env-file)
    - [Step 5 — Configure Your API Key and Model](#step-5--configure-your-api-key-and-model)
    - [Step 6 — Start the NVIDIA NIM Proxy Server](#step-6--start-the-nvidia-nim-proxy-server)
    - [Step 7 — Install Claude Code](#step-7--install-claude-code)
    - [Step 8 — Launch Claude Code (Pointed at NVIDIA NIM)](#step-8--launch-claude-code-pointed-at-nvidia-nim)
  - [Setup Guide — Windows (WSL2)](#setup-guide--windows-wsl2)
    - [Step 1 — Install WSL2](#step-1--install-wsl2)
    - [Step 2 — Install Ubuntu from the Microsoft Store](#step-2--install-ubuntu-from-the-microsoft-store)
    - [Step 3 — Open Ubuntu and Install UV](#step-3--open-ubuntu-and-install-uv)
    - [Step 4 — Install Python 3.14](#step-4--install-python-314)
    - [Step 5 — Create a Working Directory and Download NIM](#step-5--create-a-working-directory-and-download-nim)
    - [Step 6 — Edit the `.env` File](#step-6--edit-the-env-file)
    - [Step 7 — Start the NIM Proxy Server](#step-7--start-the-nim-proxy-server)
    - [Step 8 — Install and Launch Claude Code](#step-8--install-and-launch-claude-code)
  - [Running Claude Code (Daily Workflow)](#running-claude-code-daily-workflow)
  - [Supported Free Models on NVIDIA NIM](#supported-free-models-on-nvidia-nim)
  - [Challenges \& How to Handle Them](#challenges--how-to-handle-them)
  - [Benefits of This Approach](#benefits-of-this-approach)
  - [Quick Demo — What You Can Build](#quick-demo--what-you-can-build)
  - [Conclusion](#conclusion)

---

## Overview

Claude Code is Anthropic's AI-powered coding assistant that runs in your terminal. Normally it consumes credits or requires an Anthropic subscription. This guide walks you through a fully free, unlimited alternative — pointing Claude Code at **NVIDIA NIM's free inference API** instead of Anthropic's paid endpoint.

The result: you get the full Claude Code experience, in your terminal, for zero cost — powered by production-grade models like **DeepSeek V4 Pro**, **Qwen**, **GLM**, and **MiniMax** through NVIDIA's hosted inference platform.

---

## Why This Setup Exists

A lot of guides out there tell you to install **Ollama** and run models locally. That works fine on paper, but in practice it has a big problem — you need a reasonably powerful machine, and even then, local models tend to be slow on anything that isn't a high-end GPU workstation. For any real coding task, the latency becomes frustrating quickly.

NVIDIA NIM changes this completely. It hosts these same open-source models on NVIDIA's own infrastructure and exposes them through a standard OpenAI-compatible API. The free tier has **no daily token limit** — only a rate cap of **40 requests per minute**, which is more than sufficient for active development work.

Since NVIDIA's own documentation confirms Claude Code can be wired up to the NIM API, that's exactly what this setup does.

---

## Tools & Technologies Used

| Tool / Technology | Purpose | Notes |
|---|---|---|
| **Claude Code** | AI coding assistant (terminal-based) | Installed globally via `npm` |
| **NVIDIA NIM API** | Free hosted LLM inference | 40 req/min, no daily token limit |
| **DeepSeek V4 Pro** | Primary LLM model | Comparable to Claude Sonnet/Opus |
| **GLM 5.1 / Qwen / MiniMax** | Alternative free models | All available on NIM platform |
| **UV** | Fast Python package & environment manager | Replaces pip/venv for setup |
| **Python 3.14** | Runtime for the NIM proxy server | Managed via UV |
| **Node.js / npm** | Claude Code installation | Standard npm global install |
| **WSL2 + Ubuntu** | Linux environment on Windows | Required for Windows users |
| **VS Code** | Editing `.env` config files | Optional — any text editor works |
| **Bash / PowerShell** | Terminal environments | Bash preferred for all platforms |

---

## Key Points at a Glance

- ✅ Completely free — no Anthropic API credits consumed
- ✅ No GPU or powerful hardware needed
- ✅ No daily token limits on NVIDIA NIM free tier
- ✅ Rate limit: 40 requests/minute (plenty for coding sessions)
- ✅ Works on macOS, Linux, and Windows (via WSL2)
- ✅ Models are on par with Claude Sonnet and Opus quality
- ✅ Claude Code's full feature set works — file editing, project building, terminal commands
- ⚠️ NVIDIA NIM must be running locally as a proxy whenever Claude Code is in use
- ⚠️ Occasional errors during NVIDIA NIM peak hours (covered in Challenges section)

---

## Prerequisites

Before starting, make sure you have the following ready:

1. A free account on [NVIDIA NIM](https://build.nvidia.com) — phone number verification is required to generate an API key
2. **Node.js** installed on your machine (for `npm install -g @anthropic-ai/claude-code`)
3. Internet access (the NIM proxy fetches models from NVIDIA's cloud)
4. For Windows users: access to the **Microsoft Store** to install Ubuntu

---

## Setup Guide — macOS / Linux

### Step 1 — Install UV

UV is a modern Python toolchain manager. Open your terminal and run:

```bash
# macOS / Linux — get the install command from:
# https://docs.astral.sh/uv/getting-started/installation/
sudo apt-get install curl -y
curl -LsSf https://astral.sh/uv/install.sh | sh

# To add $HOME/.local/bin to your PATH, either restart your shell or run:
source $HOME/.local/bin/env
```

### Step 2 — Install Python 3.14 via UV

```bash
# sudo snap install astral-uv --classic # in case uv is not installed on machine.
uv python install 3.14
```

If it's already installed, this completes instantly. First-time installs may take a minute or two.

### Step 3 — Download the NVIDIA NIM Proxy Folder

```bash
sudo apt install git -y # install git in case if it is not installed.

git clone https://github.com/Alishahryar1/free-claude-code.git nvidia-nim

cd nvidia-nim
```

> 💡 The exact clone URL is available on [compilefuture.com](https://compilefuture.com/blog/how-to-use-claude-code-free-unlimited/) — the reference site for this video series.

### Step 4 — Create Your `.env` File

```bash
# macOS / Linux
cp .env.example .env
```

### Step 5 — Configure Your API Key and Model

Open the `.env` file in VS Code or any text editor:

```bash
code .       # Opens in VS Code
# OR
open .       # Opens Finder — then press Cmd+Shift+. to show hidden files
```

Inside `.env`, you'll see two fields to fill in:

```env
NVIDIA_NIM_API_KEY=your_api_key_here
NVIDIA_NIM_MODEL=nvidia/deepseek-v4-0709-pro

# You will see like below
MODEL="nvidia_nim/deepseek-ai/deepseek-v4-pro"
```
**To replace your model using command:**

```sh
sed -i 's|MODEL="nvidia_nim/z-ai/glm4.7"|MODEL="nvidia_nim/deepseek-ai/deepseek-v4-pro"|' .env
```

**To get your API key:**

1. Go to [https://build.nvidia.com](https://build.nvidia.com)
2. Sign up and verify your account with a phone number
3. Click **Generate API Key**
4. Name it something like `claude-code`, set expiry to **Never Expire**
5. Copy and paste the key into `.env`

**To get the model name:**

1. On the NVIDIA NIM site, click **Models**
2. Pick a model (e.g. DeepSeek V4 Pro)
3. Click **View Code**
4. Copy the model string shown (e.g. `deepseek-ai/deepseek-v4-0709-pro`)
5. In `.env`, the `nvidia/` prefix is already there — just replace the placeholder portion

### Step 6 — Start the NVIDIA NIM Proxy Server

```bash
# From inside the nvidia-nim directory

uv run uvicorn server:app --host 0.0.0.0 --port 8082

# uv run main.py
```
You'll see package downloads on the first run, then the local API server starts. **Keep this terminal window open** — Claude Code needs it running in the background.

> [!NOTE]
> *You always have to keep running this API Server in the background to use Nvida Nim with Claude Code*.

<img width="619" height="243" alt="Image" src="https://github.com/user-attachments/assets/26557fee-a6c9-463b-af2d-9b68f38a0db1" />

### Step 7 — Install Claude Code

Open a **new** terminal window and run:

```bash
# npm install -g @anthropic-ai/claude-code
curl -fsSL https://claude.ai/install.sh | bash
```

Restart your terminal once after installation.

<img width="658" height="297" alt="Image" src="https://github.com/user-attachments/assets/a8c27a24-e29b-46f9-ba86-b3585ab0ab3f" />

### Step 8 — Launch Claude Code (Pointed at NVIDIA NIM)

Navigate to your project folder, then run the startup command (it sets the `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` environment variables before invoking `claude`):

> [!CAUTION] 
> ANTHROPIC_AUTH_TOKEN="freecc" ANTHROPIC_BASE_URL="http://localhost:8082" claude

```bash
cd ~/your-project-folder

# The exact command sets env vars for the NIM endpoint — copy from compilefuture.com

# ANTHROPIC_BASE_URL=http://localhost:<port> ANTHROPIC_API_KEY=dummy claude

ANTHROPIC_AUTH_TOKEN="freecc" ANTHROPIC_BASE_URL="http://localhost:8082" claude
```

Choose **Dark Mode** when prompted, then press Enter. Claude Code will start up and connect to the local NIM proxy.

**Verify the connection:**

```
/status
```

You should see the localhost URL confirming the NIM endpoint is active.

<img width="904" height="606" alt="Image" src="https://github.com/user-attachments/assets/0656bf34-5428-415c-9e9a-3ffd0271de8a" />

---

## Setup Guide — Windows (WSL2)

Windows users need a Linux environment first. WSL2 gives you a full Ubuntu install running inside Windows — all dev tools work natively inside it.

### Step 1 — Install WSL2

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

Click **Yes** on the UAC prompt, then **restart your PC** when prompted.

### Step 2 — Install Ubuntu from the Microsoft Store

1. Open the **Microsoft Store**
2. Search for **Ubuntu**
3. Click **Get** and let it install
4. Once installed, click **Open**
5. Ubuntu will finish setting up and ask for a username and password — set these and remember them

> Your Ubuntu files live at: `\\wsl$\Ubuntu\home\<your-username>\` — accessible from File Explorer under the **Linux** section in the left panel.

### Step 3 — Open Ubuntu and Install UV

In your Ubuntu terminal:

```bash
# Use the Linux install command from https://docs.astral.sh/uv
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Step 4 — Install Python 3.14

```bash
uv python install 3.14
```

### Step 5 — Create a Working Directory and Download NIM

```bash
mkdir fcc && cd fcc
git clone <nvidia-nim-repo-url>
cd nvidia-nim
cp .env.example .env
```

### Step 6 — Edit the `.env` File

Navigate to the folder via **File Explorer**:

```
Linux → Ubuntu → Home → <your-username> → fcc → nvidia-nim
```

Open `.env` with Notepad or VS Code. Fill in your NVIDIA API key and model name exactly as described in the macOS section above.

### Step 7 — Start the NIM Proxy Server

Back in your Ubuntu terminal:

```bash
uv run main.py
```

Allow Python through the Windows firewall if prompted. Leave this terminal running.

### Step 8 — Install and Launch Claude Code

Open a second Ubuntu terminal (click the **+** arrow in Windows Terminal and select Ubuntu):

```bash
cd ~/fcc
npm install -g @anthropic-ai/claude-code
```

Then launch Claude Code with the NIM startup command (Bash version — copy from compilefuture.com):

```bash
ANTHROPIC_BASE_URL=http://localhost:<port> ANTHROPIC_API_KEY=dummy claude
```

Select **Dark Mode**, press Enter, and confirm the prompts. Run `/status` to verify the NIM connection is live.

---

## Running Claude Code (Daily Workflow)

Every time you want to use Claude Code, follow this two-step routine:

| Step | Action | Terminal |
|---|---|---|
| 1 | `cd ~/nvidia-nim && uv run main.py` | Terminal A — keep open |
| 2 | `cd ~/your-project && <nim-launch-command>` | Terminal B — work here |

If the NIM proxy isn't running, Claude Code has no endpoint to send requests to and will fail. Always start the proxy first.

---

## Supported Free Models on NVIDIA NIM

All models listed below are available at no cost on the NVIDIA NIM platform. Quality is described relative to Anthropic's own model tiers for reference.

| Model | Provider | Quality Tier | Notes |
|---|---|---|---|
| **DeepSeek V4 Pro** | DeepSeek AI | ≈ Claude Opus | Excellent for complex coding |
| **GLM 5.1** | Zhipu AI | ≈ Claude Sonnet | GLM 4.7 deprecated — use 5.1 |
| **Qwen (latest)** | Alibaba | ≈ Claude Sonnet | Strong reasoning, fast |
| **MiniMax** | MiniMax AI | ≈ Claude Sonnet | Good open-source option |

> To find the exact model string for your `.env`, go to **Models → [select model] → View Code** on the NVIDIA NIM platform and copy the identifier shown.

---

## Challenges & How to Handle Them

These are real-world friction points you may hit during setup or daily use:

**1. NVIDIA NIM Errors During Peak Hours**

The free tier occasionally returns errors when NVIDIA's infrastructure is under heavy load. This isn't something you can control. If you hit repeated failures, wait 10–15 minutes and try again. The author of this guide also covers a separate free alternative in another video that tends to be more stable during these windows.

**2. Phone Number Verification Requirement**

NVIDIA requires phone verification before you can generate an API key. This is a one-time step but can catch you off-guard if you're not expecting it. Make sure you have access to a phone number before starting.

**3. Model Deprecations**

Models on the NIM platform do get deprecated — GLM 4.7 was deprecated 9 days from the time of recording. Always check the Models tab on the NIM platform before setting your `.env`. If Claude Code starts throwing errors, a deprecated model is the first thing to check.

**4. NIM Proxy Must Always Be Running**

This is easy to forget. If you close the NIM terminal and try to use Claude Code, nothing will work. Build the habit of starting the proxy first, before anything else.

**5. Windows Environment Confusion**

On Windows, do not try to run this setup through native PowerShell. Use WSL2/Ubuntu. Most development tooling — UV, npm, Claude Code — behaves predictably in a Linux environment. PowerShell has compatibility gaps that will cost you time debugging.

**6. Hidden `.env` File on macOS**

The `.env` file is hidden by default in Finder. Press **Cmd + Shift + .** to toggle hidden file visibility, or just use `code .` from the terminal to open the folder in VS Code where it shows up normally.

---

## Benefits of This Approach

This isn't just a workaround — there are genuine advantages to running Claude Code this way:

- **Zero running cost.** No subscription, no API credits, no pay-per-token billing. The NVIDIA NIM free tier is genuinely free with no daily cap.

- **No hardware requirements.** You don't need a GPU, a powerful CPU, or extra RAM. The models run on NVIDIA's cloud. Any machine that can run a terminal can use this.

- **Production-quality models.** DeepSeek V4 Pro, Qwen, and MiniMax are serious models. They're not toy versions — they produce results comparable to Claude Sonnet and Opus on real coding tasks.

- **Full Claude Code feature set.** Because Claude Code just needs an OpenAI-compatible endpoint, everything works — multi-file edits, bash commands, project-wide refactoring, and more.

- **Cross-platform.** The same setup works on macOS, Linux, and Windows. WSL2 makes Windows a proper development environment without compromises.

- **Great for learning.** If you're learning development, DevOps, or just exploring AI-assisted coding, this removes the financial barrier entirely.

---

## Quick Demo — What You Can Build

To test the setup end to end, the guide demonstrates building a full task management web application using a single Claude Code prompt. The result — generated without any manual coding — includes:

- A complete HTML/CSS/JS frontend
- Dark mode by default
- Add, delete, and complete task functionality
- Active and Done tab views
- Zero bugs on first run

This kind of output from a single natural-language prompt is a good benchmark for verifying that your NIM connection is working correctly and the model is performing as expected.

---

## Conclusion

Getting Claude Code running for free — properly free, not just "free for 7 days" free — used to mean either paying Anthropic or wrestling with slow local models through Ollama. Neither option was great for developers on modest hardware.

NVIDIA NIM changes the equation. Their free inference API is fast, has no daily token limit, and supports models that genuinely hold up against premium paid options. Wiring Claude Code to the NIM endpoint takes about 15–20 minutes end to end, and once it's set up, the daily workflow is just two terminal commands.

The one real caveat is reliability — peak-hour errors on the NIM platform are occasional but real. For anyone doing serious production work, it's worth keeping a backup option in mind. But for learning, side projects, and general development work, this setup is hard to beat.

If you're on Windows and haven't set up WSL2 yet, this is honestly a good opportunity to do it regardless of this guide — WSL2 makes Windows a much better development machine across the board.

---

> **Reference Links**
> - NVIDIA NIM Platform: [https://build.nvidia.com](https://build.nvidia.com)
> - Claude Code Official Docs: [https://docs.anthropic.com/en/docs/claude-code](https://docs.anthropic.com/en/docs/claude-code)
> - UV Python Manager: [https://docs.astral.sh/uv](https://docs.astral.sh/uv)
> - Setup Commands & Resources: [https://compilefuture.com](https://compilefuture.com)
> - Youtube Video [Claude Code FREE UNLIMITED (No Ollama, No GPU!)](https://www.youtube.com/watch?v=7_bmIT8HZXI&list=PLJcpyd04zn7pg7uc0N5LgwRasQvjPLVVb&index=29)

> - Youtube Video [Claude Code FREE Unlimited )](https://www.youtube.com/watch?v=NSprKf-giBo&list=PLJcpyd04zn7pg7uc0N5LgwRasQvjPLVVb&index=26)

**Shortcut link**
```sh
#cmd /k "cd /d C:\free-claude-code  && uv run python server.py"
powershell.exe -NoExit -Command "cd 'C:\free-claude-code'; uv run python server.py"

# and 

powershell.exe -NoExit -Command "$env:ANTHROPIC_BASE_URL='http://localhost:8082'; $env:ANTHROPIC_AUTH_TOKEN='freccc'; claude"
```
---


