# STOP Paying for AI! Use Claude Code FREE with Ollama 🚀

A **step-by-step technical guide** to building AI-powered websites, MVPs, and applications using **Claude Code**, **Ollama**, and **VS Code** without any paid subscription.

---

## 📌 Introduction

Many developers want to use AI coding assistants like **Claude Code**, but paid subscriptions are often a barrier. This project demonstrates how to use **Claude Code completely FREE** by integrating it with **Ollama** and a cloud-hosted AI model (**Minimax M2.7**), directly inside **VS Code**.

With this setup, you can:
- Build landing pages, apps, and MVPs
- Use AI as a real coding agent
- Avoid cloud usage fees and subscriptions

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
# Bypass execution policy only for this install
Set-ExecutionPolicy Bypass -Scope Process -Force

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

## 🏁 Conclusion

This project demonstrates that **powerful AI development does not require expensive subscriptions**. By combining **Claude Code**, **Ollama**, and **Minimax M2.7**, you get a production-ready AI coding workflow at **zero cost**.

Use this setup to build, experiment, and innovate faster—without limits.

🚀 Build smarter. Build faster. Build FREE.

--Ref Link

- Youtube
  - [Use Claude Code FREE with Ollama ](https://www.youtube.com/watch?v=xMHG9pXlCpg&list=PLJcpyd04zn7oj5YyplnmW6GrkXm9LlUYq&index=12)



https://www.youtube.com/watch?v=6IW6F_y_EQE&list=PLJcpyd04zn7pg7uc0N5LgwRasQvjPLVVb&index=21


- 👉 Try Claude Code here: https://claude.com/product/claude-code
- 👉 Try NodeJS here: https://nodejs.org/en
- 👉 Try OpenRouter here: https://openrouter.ai
- 👉 OpenRouter Claude Code Doc: https://openrouter.ai/docs/guides/coding-agents/claude-code-integration


Node js is a runtime environment and claude code is build on Nodejs.