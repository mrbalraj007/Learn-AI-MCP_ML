# Claude Code + Ollama + MCP - Quick Reference Card

## 1️⃣ START CLAUDE CODE

```bash
# Start with local model (fast, cost-free, requires 8GB+ RAM)
ollama launch claude --model qwen2.5-coder:7b

# Start with cloud model (slower, better quality, zero local resources)
ollama launch claude --model qwen3.5:cloud

# Auto-approve permissions (dev/testing only)
ollama launch claude --model qwen2.5-coder:7b --dangerously-skip-permissions
```

**Aliases (Add to ~/.bashrc):**
```bash
alias claude-fast='ollama launch claude --model qwen2.5-coder:7b'
alias claude-qual='ollama launch claude --model qwen3.5:cloud'
alias claude-deep='ollama launch claude --model deepseek-coder:6.7b'
```

---

## 2️⃣ MCP SERVER MANAGEMENT (Inside Claude Code)

### View Available Servers
```
/mcp
```
Shows all connected MCP servers and their status ✓

### Add New Server
```bash
claude mcp add aws-pricing --scope user \
  -- uvx --from awslabs.aws-pricing-mcp-server@latest awslabs.aws-pricing-mcp-server

claude mcp add terraform-mcp --scope user \
  -- uvx --from terraform-mcp-server@latest terraform-mcp-server

claude mcp add eks-mcp --scope user \
  -- uvx awslabs.eks-mcp-server@latest --allow-write --allow-sensitive-data-access
```

### List All Servers
```bash
claude mcp list
```

### Remove Server
```bash
claude mcp remove [server-name]
```

### Check Server Status
```bash
claude mcp get [server-name]
```

---

## 3️⃣ OLLAMA MODEL MANAGEMENT

### Pull Models
```bash
# Lightweight, fast (7B parameters, 4.7GB)
ollama pull qwen2.5-coder:7b

# Better quality (9B parameters, 5.5GB)
ollama pull qwen3.5:9b

# Specialized for code (6.7B parameters)
ollama pull deepseek-coder:6.7b

# General purpose
ollama pull llama3

# Cloud variants (zero local storage)
ollama pull qwen3.5:cloud
ollama pull kimi-k2.5:cloud
```

### List All Models
```bash
ollama list
```

### Remove Model
```bash
ollama rm qwen2.5-coder:7b
```

### Check Ollama Status
```bash
# Verify Ollama is running
curl http://localhost:11434/api/tags

# View logs
tail -f ~/.ollama/logs/server.log
```

---

## 4️⃣ AWS SETUP

### Configure Credentials
```bash
aws configure --profile default

# When prompted:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: us-east-1
# Default output format: json
```

### Verify AWS Connection
```bash
aws sts get-caller-identity
```

### Set Environment Variables
```bash
# Add to ~/.bashrc for persistent configuration
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
```

---

## 5️⃣ KUBERNETES/EKS SETUP

### Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Configure kubeconfig for EKS
```bash
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region us-east-1
```

### Verify kubectl Access
```bash
kubectl cluster-info
kubectl get nodes
```

---

## 6️⃣ INSIDE CLAUDE CODE: PRACTICAL PROMPTS

### AWS Pricing Queries
```
"What's the monthly cost for 5 t3.large EC2 instances in us-east-1?"

"Analyze my terraform project and estimate monthly AWS costs"

"Compare costs between m5.large and t3.large instances"
```

### Terraform Queries
```
"Show me the latest AWS Terraform provider version"

"Find a Terraform module for setting up a VPC with subnets"

"What are the available versions of the aws_s3_bucket resource?"
```

### EKS Queries
```
"List all pods in my EKS cluster"

"Check the CPU and memory usage of my deployments"

"Troubleshoot why my deployment isn't starting"
```

### Combined Workflows
```
"I'm creating a Terraform project that deploys 10 Lambda functions.
Analyze the costs using aws-pricing and find the right provider version using terraform-mcp"

"Set up a Kubernetes cluster with Terraform, estimate costs, and show me deployment status on EKS"
```

---

## 7️⃣ PERMISSIONS & DEBUGGING

### Check Permissions Inside Claude Code
```
/permissions
```

Allow specific tools:
- `bash` - Execute shell commands
- `file_write`, `file_read` - File operations
- `text_editor` - Edit files

### Enable/Disable Tools
```
/permissions allow bash
/permissions deny bash
/permissions reset
```

### View Available MCP Tools
```
/mcp
```
(Lists all tools from all connected servers)

### Exit Claude Code
```
exit
```

---

## 8️⃣ ENVIRONMENT CONFIGURATION

### ~/.bashrc Additions
```bash
# Ollama + Claude Code
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_API_KEY=""

# AWS
export AWS_PROFILE=default
export AWS_REGION=us-east-1

# Quick commands
alias claude-fast='ollama launch claude --model qwen2.5-coder:7b'
alias claude-qual='ollama launch claude --model qwen3.5:cloud'
alias ollama-status='curl http://localhost:11434/api/tags'
alias claude-mcp='claude mcp list'
```

Apply changes:
```bash
source ~/.bashrc
```

---

## 9️⃣ TROUBLESHOOTING QUICK FIXES

| Problem | Solution |
|---------|----------|
| Ollama: Connection refused | `ollama serve &` |
| MCP servers not showing | `claude mcp list` → `claude mcp add [name]` → `exit` → restart |
| AWS credentials error | `aws configure --profile default` → `aws sts get-caller-identity` |
| No filesystem access | `/permissions` → Allow `file_read`, `file_write`, `bash` |
| Model requires more RAM | Switch to smaller model or use cloud variant (`:cloud`) |
| Can't write files | Check `/permissions` → ensure `file_write` is allowed |
| EKS commands fail | `kubectl cluster-info` → ensure kubeconfig is configured |

---

## 🔟 RESOURCE REQUIREMENTS

| Component | Minimum | Recommended | With Cloud Models |
|-----------|---------|-------------|-------------------|
| RAM | 8GB | 16GB | 4GB |
| Disk | 20GB | 50GB | 20GB |
| CPU | 2 cores | 4 cores | 1 core |
| Models | qwen2.5:7b | qwen3.5:9b | qwen3.5:cloud |

---

## 📋 DAILY WORKFLOW CHECKLIST

### Morning Setup (2 minutes)
```bash
# 1. Start Ollama (if not running as service)
ollama serve &

# 2. Verify connections
curl http://localhost:11434/api/tags
aws sts get-caller-identity

# 3. Launch Claude Code
ollama launch claude --model qwen2.5-coder:7b

# 4. Inside Claude Code, check servers
/mcp
```

### Within Claude Code
```
1. Ask MCP servers for infrastructure info
2. Use aws-pricing to estimate costs
3. Use terraform-mcp for IaC patterns
4. Use eks-mcp for Kubernetes ops
5. Let Claude orchestrate all three
6. Type 'exit' when done
```

---

## 🔗 ESSENTIAL LINKS

- **Claude Code Docs:** https://docs.anthropic.com/en/docs/claude-code/overview
- **Ollama Integration:** https://docs.ollama.com/integrations/claude-code
- **MCP Specification:** https://modelcontextprotocol.io
- **AWS MCP Server:** https://github.com/awslabs/mcp/tree/main/src/aws-pricing-mcp-server
- **Terraform MCP:** https://github.com/hashicorp/terraform-mcp-server
- **EKS MCP:** https://github.com/awslabs/mcp/tree/main/src/eks-mcp-server

---

## 💡 PRO TIPS

1. **Use local models for rapid iteration**, cloud models for complex reasoning
2. **Always check `/permissions` first** if tools aren't working
3. **Combine MCP servers in single prompt** - Claude orchestrates them automatically
4. **Cloud models (:cloud variants) use zero local resources** but require internet
5. **Set up aliases to launch Claude Code faster**
6. **Use `/mcp` before asking to see what tools are available**
7. **Keep AWS credentials secure** - never commit to git
8. **For production, use cloud models** - more reliable than local
9. **Local models cache results** - second run is faster
10. **Check logs** with `tail ~/.ollama/logs/server.log` when debugging

---

**Last Updated:** April 2026 | Claude Code v2.1+ | Ollama v0.14+
