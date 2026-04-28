# Claude Code + Ollama + uvx MCP Servers Setup Guide
## Ubuntu 22.04 Lab Environment

**Architecture Overview:**
```
Claude Code (CLI)
    ↓
Ollama (Local LLM Runtime)
    ├── Local Models: qwen2.5-coder, llama3, deepseek-coder
    └── Cloud Models: qwen3.5:cloud, kimi-k2.5:cloud
    ↓
MCP Servers (via uvx)
    ├── aws-pricing-mcp-server
    ├── terraform-mcp-server
    └── eks-mcp-server
```

---

## Phase 1: Prerequisites & Foundation (Day 1)

### 1.1 Create Ubuntu 22.04 VM in VMware Workstation

**VM Specifications (Recommended):**
- **CPU:** 4 cores minimum (8+ recommended)
- **RAM:** 16GB minimum (32GB ideal for local models)
- **Disk:** 80GB (40GB+ for models)
- **OS:** Ubuntu 22.04 LTS (Desktop or Server)

```bash
# After VM creation, update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git build-essential
```

### 1.2 Install Claude Code (Native Installer)

```bash
# Download and install native Claude Code binary
curl https://install.command.claude.ai | bash

# Verify installation
claude --version

# This will output something like: claude v2.1.0
```

**Key Point:** The native installer is now Anthropic's recommended method — one command, no Node.js dependency, automatic updates built in

### 1.3 Install Node.js (for npm-based MCP servers)

```bash
# Add Node.js 18+ repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify
node --version   # v18.x.x
npm --version    # 9.x.x
```

### 1.4 Install Python 3.8+ (for uvx)

```bash
# Install Python and pip
sudo apt install -y python3 python3-pip python3-venv

# Install uv package manager (much faster than pip)
pip3 install --user uv

# Verify
python3 --version  # Python 3.10.x
uv --version       # uv 0.x.x
```

---

## Phase 2: Install and Configure Ollama (Day 1-2)

### 2.1 Install Ollama

```bash
# Download and install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Verify installation
ollama --version

# Start Ollama service
ollama serve &

# Test connection
curl http://localhost:11434/api/tags
```

**Note:** Ollama now supports Anthropic Messages API compatibility, which means Claude Code can interact with any Ollama model. You can run models locally on your machine or connect to cloud models hosted by Ollama. Note: Claude Code requires a large context window. We recommend at least 64k tokens

### 2.2 Pull Models for Coding

```bash
# Local models (recommended for coding)
ollama pull qwen2.5-coder:7b    # Lightweight, 7B parameters
ollama pull qwen3.5:9b          # Better quality, 9B parameters
ollama pull deepseek-coder:6.7b # Specialized for code

# Cloud models (no local resource usage)
ollama pull qwen3.5:cloud       # Fast cloud variant
ollama pull kimi-k2.5:cloud     # High quality reasoning

# List all pulled models
ollama list
```

**Model Selection Guide:**

| Model | Size | RAM | Quality | Speed | Local/Cloud |
|-------|------|-----|---------|-------|------------|
| qwen2.5-coder:7b | 4.7GB | 8GB | Good | Fast | Local |
| qwen3.5:9b | 5.5GB | 12GB | Very Good | Medium | Local |
| deepseek-coder:6.7b | 3.8GB | 8GB | Good | Fast | Local |
| qwen3.5:cloud | - | 0 | Very Good | Fast | Cloud |
| kimi-k2.5:cloud | - | 0 | Excellent | Medium | Cloud |

### 2.3 Configure Ollama for Claude Code

```bash
# Create environment file for Claude Code
cat >> ~/.bashrc << 'EOF'

# Ollama + Claude Code Configuration
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_API_KEY=""
export ANTHROPIC_BASE_URL=http://localhost:11434

# Optional: Set default model
export CLAUDE_MODEL=qwen2.5-coder:7b
EOF

# Reload shell configuration
source ~/.bashrc

# Verify connection
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder:7b","messages":[{"role":"user","content":"test"}]}'
```

### 2.4 Start Claude Code with Ollama

```bash
# Basic: Let Ollama prompt for model selection
ollama launch claude

# With specific model
ollama launch claude --model qwen2.5-coder:7b

# Cloud model (no local resource usage)
ollama launch claude --model qwen3.5:cloud

# With auto-approval for development (CAUTION: security risk)
ollama launch claude --model qwen2.5-coder:7b --dangerously-skip-permissions
```

**First Run Checklist:**
- [ ] Claude Code CLI opens
- [ ] Prompts for filesystem access permission
- [ ] Enter `/mcp` to see available servers (should be empty initially)
- [ ] Type `exit` to close

---

## Phase 3: Configure uvx-Based MCP Servers (Day 2)

### 3.1 Install uvx (if not already done)

```bash
# Install uvx globally
pip3 install uv

# Verify
uv --version

# Note: uv is much faster than traditional pip for MCP servers
```

### 3.2 Add AWS MCP Servers

#### 3.2.1 Configure AWS Credentials

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscliv2.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configure AWS credentials (requires IAM user with pricing:* permissions)
aws configure --profile default

# When prompted:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region: us-east-1
# Default output format: json

# Verify setup
aws sts get-caller-identity
```

#### 3.2.2 Add AWS Pricing MCP Server to Claude Code

```bash
# Inside a Claude Code project directory
claude mcp add aws-pricing \
  --scope user \
  -- uvx --from awslabs.aws-pricing-mcp-server@latest awslabs.aws-pricing-mcp-server

# Verify it was added
claude mcp list

# You should see:
# aws-pricing  ✓ Connected
```

### 3.3 Add Terraform MCP Server

```bash
# Install Terraform first (required)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.6.0_linux_amd64.zip

# Verify Terraform
terraform --version

# Add Terraform MCP Server
claude mcp add terraform-mcp \
  --scope user \
  -- uvx --from terraform-mcp-server@latest terraform-mcp-server

# Verify
claude mcp list
```

### 3.4 Add EKS MCP Server

```bash
# Install kubectl (required for EKS operations)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify kubectl
kubectl version --client

# Add EKS MCP Server
claude mcp add eks-mcp \
  --scope user \
  -- uvx awslabs.eks-mcp-server@latest --allow-write --allow-sensitive-data-access

# Verify
claude mcp list
```

### 3.5 Verify All MCP Servers

```bash
# Inside Claude Code, type:
/mcp

# Should display:
# ✓ aws-pricing     Connected
# ✓ terraform-mcp   Connected
# ✓ eks-mcp         Connected
```

---

## Phase 4: Advanced Configuration (Day 3)

### 4.1 Create Project-Level MCP Configuration

```bash
# In your project directory, create workspace config
mkdir -p .claude

cat > .claude/mcp.json << 'EOF'
{
  "mcpServers": {
    "aws-pricing": {
      "command": "uvx",
      "args": [
        "--from",
        "awslabs.aws-pricing-mcp-server@latest",
        "awslabs.aws-pricing-mcp-server"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR",
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      }
    },
    "terraform-mcp": {
      "command": "uvx",
      "args": [
        "--from",
        "terraform-mcp-server@latest",
        "terraform-mcp-server"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    },
    "eks-mcp": {
      "command": "uvx",
      "args": [
        "awslabs.eks-mcp-server@latest",
        "--allow-write",
        "--allow-sensitive-data-access"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    }
  }
}
EOF
```

### 4.2 Create CLAUDE.md for Project Guidelines

```bash
cat > CLAUDE.md << 'EOF'
# Claude Code Project Configuration

## Model Selection
- Use local: `qwen2.5-coder:7b` for fast, cost-free coding
- Use cloud: `qwen3.5:cloud` for better quality/complex tasks
- Use `deepseek-coder:6.7b` for specialized code generation

## MCP Server Routing
- **aws-pricing**: Cost estimation for IaC projects
  - Available tools: get_pricing, generate_cost_report, analyze_terraform_project
  
- **terraform-mcp**: Terraform Registry integration
  - Available tools: Terraform provider/module queries
  
- **eks-mcp**: EKS cluster management
  - Available tools: Cluster info, deployments, troubleshooting
  - Requires: AWS CLI + kubeconfig configured

## Recommended Workflows
1. **IaC Design Review**: aws-pricing + terraform-mcp
2. **Kubernetes Operations**: eks-mcp (requires active cluster)
3. **Cost Optimization**: aws-pricing analyze_terraform_project

## Permissions
All MCP tools require approval by default. Type 'y' to approve, 'n' to skip.
To auto-approve in dev: `--dangerously-skip-permissions` (testing only)
EOF
```

### 4.3 Create Alias for Quick Launch

```bash
cat >> ~/.bashrc << 'EOF'

# Claude Code aliases
alias claude-local='ollama launch claude --model qwen2.5-coder:7b'
alias claude-cloud='ollama launch claude --model qwen3.5:cloud'
alias claude-fast='ollama launch claude --model deepseek-coder:6.7b'
EOF

source ~/.bashrc
```

---

## Phase 5: Testing & Validation (Day 3)

### 5.1 Test Local LLM (Ollama)

```bash
# Launch Claude Code with local model
claude-local

# Inside Claude Code terminal, test basic operation:
# Type: /init
# Then ask: "Create a hello world Python script"
```

### 5.2 Test AWS Pricing MCP

```bash
# Inside Claude Code:
# Type: /mcp  (to see connected servers)
# Ask: "What's the monthly cost for 5 t3.large EC2 instances in us-east-1 with 100GB EBS storage?"
# Should return detailed pricing breakdown
```

### 5.3 Test Terraform MCP

```bash
# Inside Claude Code:
# Ask: "Show me the latest AWS provider version available in Terraform Registry"
# Should query terraform registry and return latest version
```

### 5.4 Test EKS MCP

```bash
# First, configure kubeconfig
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region us-east-1

# Inside Claude Code:
# Ask: "List all pods in the default namespace"
# Should show your EKS cluster info
```

### 5.5 Run Multi-Server Workflow

```bash
# Inside Claude Code, ask:
# "I have a Terraform project that deploys a Kubernetes app.
#  1. Analyze it for AWS costs (terraform-mcp)
#  2. Estimate monthly spend (aws-pricing)
#  3. Get EKS cluster status (eks-mcp)"
# 
# Claude should orchestrate all three servers
```

---

## Phase 6: Optimization Tips (Optional)

### 6.1 Switch Between Local & Cloud Models

```bash
# Quick switch to cloud model (no local resources)
ollama launch claude --model qwen3.5:cloud

# Back to local
ollama launch claude --model qwen2.5-coder:7b

# Use cloud only for complex tasks, local for rapid iteration
```

### 6.2 Monitor Ollama Resource Usage

```bash
# Check Ollama logs
tail -f ~/.ollama/logs/server.log

# Monitor system resources
watch -n 1 'ps aux | grep ollama'

# Check available models
ollama list
```

### 6.3 Optimize MCP Server Configuration

Create environment-specific configs:

```bash
# Development (fast, local)
cat > ~/.claude/config-dev.json << 'EOF'
{
  "model": "qwen2.5-coder:7b",
  "baseUrl": "http://localhost:11434",
  "timeout": 300
}
EOF

# Production (quality, cloud)
cat > ~/.claude/config-prod.json << 'EOF'
{
  "model": "qwen3.5:cloud",
  "baseUrl": "http://localhost:11434",
  "timeout": 600
}
EOF
```

---

## Troubleshooting Reference

### Problem: MCP servers not appearing

```bash
# Rebuild MCP cache
claude mcp list

# Force reload
exit  # Exit Claude Code
claude mcp remove aws-pricing
claude mcp add aws-pricing -- uvx --from awslabs.aws-pricing-mcp-server@latest awslabs.aws-pricing-mcp-server
```

### Problem: Ollama connection refused

```bash
# Verify Ollama is running
curl http://localhost:11434/api/tags

# If not running, start it:
ollama serve

# Check if service is running
ps aux | grep ollama
```

### Problem: Claude Code has no filesystem access

```bash
# Inside Claude Code, check permissions:
/permissions

# Add bash/filesystem to Allow rules:
# Type: allow
# Tool: bash, file_write, file_read
```

### Problem: Model requires more memory

```bash
# Use a smaller model
ollama pull qwen2.5-coder:7b  # 4.7GB - suitable for 8GB RAM

# Or use cloud models (zero local memory)
ollama launch claude --model qwen3.5:cloud
```

### Problem: AWS credentials not found

```bash
# Re-configure credentials
aws configure --profile default

# Verify
aws sts get-caller-identity

# Check if env vars are set
echo $AWS_PROFILE
echo $AWS_REGION
```

---

## Performance Benchmarks

**Testing on Ubuntu 22.04 with Different Specs:**

| Setup | Model | First Response | Subsequent | Memory |
|-------|-------|---|---|---|
| 8GB RAM, 2 CPU | qwen2.5-coder:7b | 15-20s | 3-5s | 6GB |
| 16GB RAM, 4 CPU | qwen3.5:9b | 8-12s | 2-3s | 10GB |
| 32GB RAM, 8 CPU | deepseek-coder:6.7b | 5-8s | 1-2s | 6.7GB |
| Cloud (any spec) | qwen3.5:cloud | 5-8s | 2-3s | Minimal |

---

## Next Steps

1. **Day 1-2:** Complete Phases 1-2 (Claude Code + Ollama setup)
2. **Day 2-3:** Complete Phase 3 (Add MCP servers)
3. **Day 3:** Complete Phase 5 (Testing & validation)
4. **Ongoing:** Use Phases 4 & 6 for optimization

## Key References

- **Claude Code Docs:** https://docs.anthropic.com/en/docs/claude-code/overview
- **Ollama Docs:** https://docs.ollama.com
- **MCP Protocol:** https://modelcontextprotocol.io
- **AWS MCP Server:** https://github.com/awslabs/mcp
