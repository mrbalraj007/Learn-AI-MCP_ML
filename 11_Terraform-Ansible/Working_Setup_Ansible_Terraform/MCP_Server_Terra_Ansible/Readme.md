**Prerequisites Check**
First, confirm your foundation is solid:
```sh
# Verify these are all working before proceeding
claude --version
uv --version
uvx --version
python3 --version
aws sts get-caller-identity
```

**MCP Server 1 — Terraform MCP (HashiCorp Official)**

This is the official HashiCorp server. It gives Claude access to the Terraform Registry — providers, modules, resource docs.

**Step 1 — Download the binary**

```sh
# Grab the latest release from HashiCorp GitHub
curl -LO https://github.com/hashicorp/terraform-mcp-server/releases/latest/download/terraform-mcp-server_linux_amd64.tar.gz

or

wget https://github.com/hashicorp/terraform-mcp-server/archive/refs/tags/v0.5.2.zip

# Extract and install
tar -xzf terraform-mcp-server_linux_amd64.tar.gz

sudo mv terraform-mcp-server_linux_amd64 terraform-mcp-server

sudo mv terraform-mcp-server /usr/local/bin/

sudo chmod +x /usr/local/bin/terraform-mcp-server
```
---
<details>
<summary><b>Follow Option B to download Terraform MCP Server</b></summary><br>

Option B — If the Filename Doesn't Match (Find Exact Release URL)
GitHub sometimes changes release artifact names between versions. Check the exact filenames first:

```sh
# List all assets for the latest release
curl -s https://api.github.com/repos/hashicorp/terraform-mcp-server/releases/latest \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
print('Tag:', data['tag_name'])
print('Assets:')
for a in data['assets']:
    print(' -', a['name'], '|', a['browser_download_url'])
"
```
That will print the exact filenames available. Pick the linux_amd64 one and download it directly:
bash# Example (URL will match what the above command printed)
```sh
curl -LO <exact-url-from-above-output>
```
</details>

---

if above failed then follow below

Fix — Build from Source (Source Already There)
Step 1 — Install Go
```sh
# Check if Go is already installed
go version

# If not, install it
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz -P /tmp
sudo tar -C /usr/local -xzf /tmp/go1.22.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify
go version
# Expected: go version go1.22.4 linux/amd64
```
Step 2 — Build the binary from existing source
```sh
# The source is already here from your earlier git clone
cd /usr/local/bin/terraform-mcp-server

# Download Go module dependencies
go mod download

# Build the binary, output to /tmp first
go build -o /tmp/terraform-mcp-server ./cmd/terraform-mcp-server

# Verify the binary was created and is the right type
file /tmp/terraform-mcp-server
# Expected: ELF 64-bit LSB executable, x86-64
```
Step 3 — Install the compiled binary
```sh
# Move binary to a clean location
sudo mv /tmp/terraform-mcp-server /usr/local/bin/terraform-mcp-server-bin

# Remove the source directory that's polluting /usr/local/bin
sudo rm -rf /usr/local/bin/terraform-mcp-server

# Put the binary in place
sudo mv /usr/local/bin/terraform-mcp-server-bin /usr/local/bin/terraform-mcp-server
sudo chmod +x /usr/local/bin/terraform-mcp-server

# Confirm it's a FILE not a directory
ls -la /usr/local/bin/terraform-mcp-server
# Must start with -rwx (not drwx)
```
Step 4 — Smoke test
```sh
terraform-mcp-server --help
```
Expected output — something like:
```sh
Usage of terraform-mcp-server:
  -transport string
        Transport type to use (stdio, sse) (default "stdio")
```
**Step 5 — Register with Claude Code**
```sh
claude mcp add terraform-mcp --scope user -- /usr/local/bin/terraform-mcp-server stdio

# Verify
claude mcp list
```





**Verify**
terraform-mcp-server --help

**Clean up**
rm -f terraform-mcp-server_linux_amd64.tar.gz
```

**Step 2 — Register with Claude Code**
```bash
claude mcp add terraform-mcp --scope user -- /usr/local/bin/terraform-mcp-server stdio
```
**Step 3 — Verify it connected**
```bash
claude mcp list
```
** Should show terraform-mcp with a connected status**




# Configure Ansible MCP Server

1. If installed using APT (most common)

**Check first:**
```sh
node -v
which node
```
*if older node then remove:*
```sh
sudo apt remove nodejs -y
sudo apt purge nodejs -y
sudo apt autoremove -y
```


**MCP Server 2 — Ansible MCP (Community)**

The most stable Ansible MCP is ansible-mcp-server by dkattan — it wraps ansible, ansible-playbook, ansible-inventory, and ansible-doc as MCP tools Claude can call directly.

**Step 1 — Install Ansible itself first**

```sh
sudo apt update
sudo apt install -y ansible

# Verify
ansible --version
# Should show: ansible [core 2.x.x]
```
**Step 2 — Install Node.js (if not already done)**

The Ansible MCP server is npm-based, so you need Node 24+:

**Official Ansible MCP (if you want the Red Hat one)**

You need to upgrade Node.js from v20 → v24 first:

```sh
# Remove v20, install v24
sudo apt remove nodejs -y
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version   # Must show v24.x.x

# Then install the MCP server
npm install -g @ansible/ansible-mcp-server

# Register with Claude Code
claude mcp add ansible-mcp \
  --scope user \
  -e WORKSPACE_ROOT=$HOME \
  -- npx -y @ansible/ansible-mcp-server --stdio
```

Fix — User-Owned npm Global Directory
```bash
# Step 1 — Create a user-owned global directory
mkdir -p ~/.npm-global

# Step 2 — Tell npm to use it
npm config set prefix '~/.npm-global'

# Step 3 — Add it to your PATH permanently
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Step 4 — Verify npm now points to your user directory
npm config get prefix
# Must show: /home/dc-ops/.npm-global
```
Now retry the install:
```sh
npm install -g @ansible/ansible-mcp-server
```

Step 4 — Register with Claude Code
```bash
claude mcp add ansible-mcp \
  --scope user \
  -e WORKSPACE_ROOT=$HOME \
  -- npx -y @ansible/ansible-mcp-server --stdio
```

**Remove MCP Server**
```sh
claude mcp remove ansible-mcp
```

> Prompt
*Once both are confirmed working, you'll be able to ask Claude things like "Write a playbook to deploy nginx on my inventory group webservers and estimate the EC2 cost for the target instances" — with terraform-mcp and ansible-mcp working together.*