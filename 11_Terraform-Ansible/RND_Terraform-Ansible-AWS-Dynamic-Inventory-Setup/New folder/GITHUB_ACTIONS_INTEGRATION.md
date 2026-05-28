# GitHub Actions + CloudWatch Integration Guide
# Complete CI/CD and Monitoring Setup

## 📋 Overview

This solution provides **complete infrastructure automation** with:

1. **CI/CD Pipeline** (GitHub Actions)
   - Terraform validation and formatting
   - Security scanning (Checkov + terraform-compliance)
   - Automated planning and applying
   - Cost analysis (Infracost)

2. **Drift Detection** (GitHub Actions + Terraform)
   - Daily infrastructure drift detection
   - Automatic GitHub Issue creation/updates
   - Slack and email notifications
   - Optional auto-remediation

3. **CloudWatch Monitoring**
   - EC2 instance monitoring (CPU, network, status)
   - Custom metrics (disk usage)
   - SNS alerts
   - CloudWatch dashboards
   - Event-based notifications

---

## 🎯 Architecture

```
GitHub Repository
├── Main Branch (Protected)
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── modules/
│   │   │   ├── ec2/
│   │   │   └── cloudwatch/
│   │   └── ...
│   └── .github/workflows/
│       ├── terraform-ci-cd.yml
│       ├── terraform-drift-detection.yml
│       └── terraform-cost-monitoring.yml
│
│ GitHub Actions Triggers
│ ├── On Push: CI/CD pipeline runs
│ ├── Daily: Drift detection runs
│ ├── Weekly: Cost analysis runs
│
AWS Account
├── OIDC Provider (for GitHub Actions)
├── IAM Role (github-actions-terraform-role)
├── EC2 Instances
│   └── CloudWatch Agent (optional)
├── CloudWatch
│   ├── Alarms
│   ├── Dashboards
│   ├── Log Groups
│   └── Event Rules
├── SNS Topics
│   └── Subscriptions (Email, Slack, etc.)
└── S3 Bucket (Terraform state)

External Services
├── Slack (notifications)
├── Email (alerts)
├── Infracost (cost analysis)
└── GitHub Issues (drift tracking)
```

---

## 📦 Files Created

### Terraform Modules
```
terraform/
├── modules/
│   ├── ec2/                    (existing)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── cloudwatch/             (NEW)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                     (update to use cloudwatch module)
├── variables.tf
└── outputs.tf
```

### GitHub Actions Workflows
```
.github/workflows/
├── terraform-ci-cd.yml         (CI/CD pipeline)
├── terraform-drift-detection.yml (Drift detection)
└── terraform-cost-monitoring.yml (Cost analysis)
```

### Documentation
```
docs/
├── GITHUB_ACTIONS_SETUP.md     (This file)
└── [other docs]
```

---

## 🚀 Quick Start (30 minutes)

### Step 1: Prepare AWS (10 minutes)

```bash
# 1. Create OIDC Provider in AWS
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Create CloudWatch module in terraform
mkdir -p terraform/modules/cloudwatch
# Copy CloudWatch module files (main.tf, variables.tf, outputs.tf)

# 3. Update terraform/main.tf to use CloudWatch module
# Add: module "cloudwatch" { ... }

# 4. Deploy
cd terraform
terraform init
terraform apply

# Note the outputs
terraform output -json
```

### Step 2: Configure GitHub (10 minutes)

```bash
# 1. Create GitHub Secrets
gh secret set AWS_ROLE_TO_ASSUME --body "arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform-role"
gh secret set INFRACOST_API_KEY --body "YOUR_API_KEY"
gh secret set SLACK_WEBHOOK_URL --body "YOUR_WEBHOOK_URL"

# 2. Create GitHub Workflows directory
mkdir -p .github/workflows

# 3. Add workflow files
# Copy all .yml files from workflows directory

# 4. Commit and push
git add .github/
git commit -m "feat: add GitHub Actions CI/CD workflows"
git push
```

### Step 3: Test Workflows (10 minutes)

```bash
# 1. Create test branch
git checkout -b test/ci-cd
echo "# Test" > README_TEST.md
git add .
git commit -m "test: CI/CD pipeline"
git push origin test/ci-cd

# 2. Create Pull Request
# Go to GitHub → Create PR

# 3. Wait for workflows to complete
# Check: Actions tab in GitHub

# 4. Review results
# - terraform-validate ✓
# - security-scan ✓
# - terraform-plan ✓

# 5. Merge PR (requires approval + checks)
```

---

## 📊 Workflow Execution Flow

### CI/CD Pipeline (On Push to main)

```
1. terraform-validate (5 min)
   ├─ terraform init
   ├─ terraform validate
   └─ terraform fmt --check

2. security-scan (5 min)
   ├─ Checkov scan
   ├─ terraform-compliance scan
   └─ Upload results to GitHub

3. terraform-plan (5 min)
   ├─ terraform plan
   ├─ terraform show
   └─ Comment on PR

4. terraform-apply (10 min) [Manual trigger]
   ├─ Download plan
   ├─ terraform apply
   └─ Create EC2 instances

5. documentation (2 min)
   └─ Generate README.md

Total: 27 minutes (sequential)
```

### Drift Detection (Daily 08:00 UTC)

```
1. drift-detection (10 min)
   ├─ terraform refresh
   ├─ terraform plan
   └─ Detect changes

2. manage-drift-issues (2 min)
   ├─ Create GitHub Issue if drift found
   └─ Close Issue if drift resolved

3. notify-drift (1 min)
   ├─ Slack notification
   └─ Email notification

4. auto-remediate (10 min) [Optional]
   └─ terraform apply -auto-approve

Total: 23 minutes
```

### Cost Monitoring (Weekly Monday 09:00 UTC)

```
1. cost-analysis (5 min)
   ├─ infracost breakdown
   └─ Comment on PR

2. performance-benchmarks (10 min)
   └─ Fetch CloudWatch metrics

3. cost-trend-analysis (2 min)
   └─ Generate trend chart

4. aws-resource-audit (5 min)
   └─ List EC2, security groups, etc.

Total: 22 minutes
```

---

## 🔒 Security Configuration

### AWS IAM Policy (github-actions-terraform-role)

**Minimum permissions required:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "cloudwatch:*",
        "cloudformation:*",
        "iam:*",
        "logs:*",
        "sns:*",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "*"
    }
  ]
}
```

**Production recommendation:** Use resource-level restrictions

### GitHub Secrets

| Secret | Type | Required |
|--------|------|----------|
| `AWS_ROLE_TO_ASSUME` | IAM Role ARN | ✅ Required |
| `INFRACOST_API_KEY` | API Key | ✅ Required |
| `SLACK_WEBHOOK_URL` | Webhook URL | ⚠️ Optional |
| `ALERT_EMAIL` | Email | ⚠️ Optional |
| `MAIL_*` | SMTP Config | ⚠️ Optional |

### Branch Protection Rules

```
Branch: main
├─ Require pull request review (1 approval)
├─ Require status checks to pass:
│  ├─ terraform-validate
│  ├─ security-scan
│  └─ terraform-plan
├─ Require code reviews before merging
├─ Dismiss stale PR reviews
└─ Require branches to be up to date
```

---

## 📈 Monitoring & Observability

### CloudWatch Dashboard

**Metrics monitored:**
- CPU Utilization (EC2)
- Network In/Out (EC2)
- Status Check Failed (EC2)
- Disk Usage (Custom - if CloudWatch Agent enabled)
- Root Volume IOPS

**Access:**
```bash
# From AWS Console
CloudWatch → Dashboards → {environment}-{project_name}-dashboard

# Via AWS CLI
aws cloudwatch describe-dashboards --dashboard-name-prefix dev-k8s-cluster
```

### SNS Alerts

**Alarm triggers:**
- CPU > 80% for 10 minutes
- Status check failed
- Network inbound > 1GB per 5 min
- Disk usage > 85% (if enabled)

**Notifications sent to:**
- Email (SNS subscription)
- Slack (CloudWatch → EventBridge → SNS → Webhook)

### GitHub Issues for Drift

**Automatic issue creation when:**
- Drift detected: Resources modified outside Terraform
- Issue title: "🔄 Infrastructure Drift Detected - X resource(s) affected"
- Issue labels: bug, infrastructure, automated

**Auto-closes when:**
- Drift remediated
- Infrastructure matches Terraform state

---

## 🔧 Configuration Examples

### Use Case 1: Change EC2 Instance Type

**Workflow:**
1. Edit `terraform/terraform.tfvars`: `instance_type = "t3.large"`
2. Push to `develop` branch
3. GitHub Actions runs:
   - Validates Terraform
   - Runs security scans
   - Plans changes (shows new instance type)
   - Comments on PR
4. Create PR from `develop` to `main`
5. Review and approve
6. Merge triggers `terraform apply`
7. EC2 instances updated

**Time: ~30 minutes**

### Use Case 2: Infrastructure Drift Detected

**Automatic workflow:**
1. Daily 08:00 UTC drift detection runs
2. Detects someone manually modified EC2 in AWS Console
3. Creates GitHub Issue: "Infrastructure Drift Detected"
4. Slack notification sent to #ops channel
5. Email alert sent to devops@company.com
6. Options:
   - Fix in Terraform and apply
   - Accept changes and update state
   - Auto-remediate (revert to Terraform state)

**Time: Immediate notification, manual resolution**

### Use Case 3: Cost Analysis on PR

**Workflow:**
1. Create PR with EC2 instance count increase
2. GitHub Actions runs Infracost
3. Cost estimate: "$X/month increase"
4. Comment on PR shows cost breakdown
5. Team reviews cost impact
6. Approve if acceptable

**Time: ~5 minutes**

---

## 🐛 Troubleshooting

### Workflow: "OIDC token not found"

**Symptoms:**
```
Error: Failed to assume role arn:aws:iam::...:role/github-actions-terraform-role
```

**Solution:**
```bash
# 1. Verify OIDC provider exists
aws iam list-open-id-connect-providers

# 2. Check role trust policy
aws iam get-role-policy --role-name github-actions-terraform-role --policy-name AssumeRolePolicy

# 3. Verify repo in condition:
# "token.actions.githubusercontent.com:sub" = "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main"

# 4. Fix if needed
aws iam update-assume-role-policy --role-name github-actions-terraform-role \
    --policy-document file://trust-policy.json
```

### Workflow: "Insufficient permissions"

**Solution:**
```bash
# 1. Check attached policies
aws iam list-attached-role-policies --role-name github-actions-terraform-role

# 2. Check inline policies
aws iam list-role-policies --role-name github-actions-terraform-role
aws iam get-role-policy --role-name github-actions-terraform-role --policy-name <policy-name>

# 3. Attach missing policies
aws iam attach-role-policy --role-name github-actions-terraform-role \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# For production: Use resource-specific policies
```

### Workflow: "State lock error"

**Solution:**
```bash
# 1. View locks
aws dynamodb scan --table-name terraform-locks --region us-east-1

# 2. Force unlock if stuck
terraform force-unlock <LOCK_ID>

# 3. Or delete lock entry from DynamoDB
aws dynamodb delete-item \
    --table-name terraform-locks \
    --key '{"LockID": {"S": "terraform-state-key"}}'
```

### Drift Detection: "No issues created"

**Check:**
```bash
# 1. Verify GitHub token has permissions
gh auth status

# 2. Check workflow logs
gh run list --workflow terraform-drift-detection.yml
gh run view <run-id> --log

# 3. Manually test issue creation
gh issue create --title "Test Issue" --body "Test"
```

---

## 📋 Maintenance Checklist

### Weekly
- [ ] Review GitHub Actions workflow runs
- [ ] Check CloudWatch alarms
- [ ] Review cost trends

### Monthly
- [ ] Update Terraform and GitHub Actions
- [ ] Review security scan results
- [ ] Audit IAM permissions
- [ ] Clean up old artifacts

### Quarterly
- [ ] Review and update branch protection rules
- [ ] Audit Slack/email subscriptions
- [ ] Capacity planning based on costs
- [ ] Disaster recovery testing

---

## 📚 Related Documentation

- `SETUP_GUIDE.md` - Initial Terraform + Ansible setup
- `README.md` - Project overview
- `GITHUB_ACTIONS_SETUP.md` - Detailed GitHub Actions configuration

---

## 🎓 Learning Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [CloudWatch User Guide](https://docs.aws.amazon.com/cloudwatch/)
- [Infracost Docs](https://www.infracost.io/docs/)

---

**Version:** 1.0  
**Last Updated:** 2024  
**Audience:** DevOps Engineers, Infrastructure Teams
