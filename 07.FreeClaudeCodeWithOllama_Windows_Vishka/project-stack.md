# Complete Project Stack — Tools & Technologies

> Everything you need to build this project, organised by phase.

---

## Phase 1: Local Development

| Tool | Version | Purpose |
|---|---|---|
| Git | any recent | Version control |
| Node.js | 18+ | Run microservices (React frontend + 6 Node.js backends) |
| npm | bundled with Node | Package management, run scripts |
| Docker | any recent | Build and run containers locally |
| Docker Compose | bundled with Docker Desktop | Orchestrate all 10 containers locally (7 services + Postgres + Prometheus + Grafana) |

---

## Phase 2: AWS Infrastructure (Terraform)

| Tool | Version | Purpose |
|---|---|---|
| Terraform | >= 1.5 | Provision VPC, EKS, ECR, install ArgoCD + Prometheus via Helm |
| AWS CLI | v2 | Authenticate with AWS, run `aws eks update-kubeconfig` |
| kubectl | any recent | Interact with the EKS cluster, apply manifests, port-forward, check pods |
| Helm | used by Terraform (no direct install needed) | Terraform uses it to install ArgoCD and kube-prometheus-stack charts |

---

## Phase 3: CI/CD

| Tool | Purpose |
|---|---|
| GitHub Actions | CI pipeline runner (configured in `.github/workflows/ci.yml`) |
| AWS ECR | Docker image registry (7 repositories — one per service) |

**GitHub Actions used in the pipeline:**
- `actions/checkout@v4`
- `aws-actions/configure-aws-credentials@v4`

---

## Phase 4: GitOps (ArgoCD + Kustomize)

| Tool | Purpose |
|---|---|
| ArgoCD | Installed in-cluster by Terraform — watches Git repo and auto-syncs changes |
| Kustomize | kubectl's built-in kustomize (`kubectl apply -k`) — no separate install needed |

---

## Phase 5: Observability

| Tool | Purpose |
|---|---|
| Prometheus | Metrics collection (installed via kube-prometheus-stack Helm chart) |
| Grafana | Metrics dashboards (installed alongside Prometheus) |
| Fluent Bit | Optional — forwards pod logs to CloudWatch (Helm-installed DaemonSet) |
| AWS CloudWatch | Log aggregation (optional Fluent Bit target) |

---

## Phase 6: AIOps (Kira)

| Tool | Version | Purpose |
|---|---|---|
| Python | 3.10+ (3.12 for Lambda) | Run the Streamlit UI and Lambda functions |
| boto3 | pip install | AWS SDK for Lambda functions |
| Streamlit | pip install | Web UI for the AIOps assistant |
| AWS Bedrock | — | Managed AI agent service (enable model access in AWS Console) |
| AWS Lambda | — | 3 functions: `fetch_logs`, `fetch_metrics`, `fetch_health` |

---

## AI Assistant Setup (Claude Code + MCP)

| Tool | Version | Purpose |
|---|---|---|
| Claude Code | latest (`npm install -g @anthropic-ai/claude-code`) | AI assistant throughout the project |
| uv (uvx) | latest | Python package runner for MCP servers |
| AWS credentials | — | IAM user with EKS + ECR + Bedrock permissions |

**MCP Servers** (installed automatically via `uvx`):

| Server | Purpose |
|---|---|
| `awslabs.eks-mcp-server` | Kubernetes / EKS operations |
| `awslabs.terraform-mcp-server` | Terraform commands + docs |
| `awslabs.aws-pricing-mcp-server` | Cost lookups |
| `awslabs.core-mcp-server` | Deprecated orchestration layer |

---

## Cloud Services (AWS)

| Service | Purpose |
|---|---|
| VPC | 3-AZ network for the EKS cluster |
| EKS | Managed Kubernetes (m7i-flex.large nodes, 1–2 nodes) |
| ECR | 7 Docker image repositories |
| Bedrock | AI agent hosting (Kira) |
| Lambda | 3 functions for AIOps agent tooling |
| CloudWatch | Log aggregation from Fluent Bit |
| IAM | Roles for Lambda, Bedrock Agent, and GitHub Actions CI user |

---

> **Summary:** ~15 tools to install locally + 5 AWS services to provision, end to end.
