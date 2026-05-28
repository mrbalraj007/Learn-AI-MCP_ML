# GitHub Actions Secrets & Configuration Guide
# File: docs/GITHUB_ACTIONS_SETUP.md

## Overview

This guide explains how to configure GitHub Actions for automated Terraform CI/CD, drift detection, and cost analysis.

---

## Prerequisites

1. GitHub Repository with proper branch protection
2. AWS Account with IAM permissions
3. GitHub Secrets configured
4. Optional: Slack workspace for notifications
5. Optional: Email for alerts

---

## Part 1: AWS OIDC Configuration

### Why OIDC?
- ✅ No long-lived AWS credentials stored in GitHub
- ✅ Short-lived temporary credentials
- ✅ Audit trail through CloudTrail
- ✅ Secure by design

### Step 1.1: Create IAM OIDC Provider

```bash
# Run this in AWS CLI (with admin credentials)
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 1.2: Create IAM Role for GitHub Actions

Create file: `terraform/iam/github-actions-role.tf`

```hcl
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:YOUR_GITHUB_ORG/YOUR_REPO:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "github_terraform" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  
  # Note: Use more restrictive policy in production
  # Minimum required:
  # - ec2:*
  # - cloudwatch:*
  # - cloudformation:*
  # - iam:*
}

# Output the role ARN for GitHub Actions
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

data "aws_caller_identity" "current" {}
```

### Step 1.3: Deploy the IAM Role

```bash
cd terraform
terraform apply

# Note the output:
# github_actions_role_arn = "arn:aws:iam::123456789012:role/github-actions-terraform-role"
```

---

## Part 2: GitHub Secrets Configuration

### Step 2.1: Add Secrets to GitHub Repository

Go to: **GitHub Repo → Settings → Secrets and variables → Actions**

Add these secrets:

#### Required Secrets

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::123456789012:role/github-actions-terraform-role` | IAM role ARN from Step 1.3 |
| `INFRACOST_API_KEY` | [Get from infracost.io](https://www.infracost.io/docs/features/github_actions/) | For cost analysis |

#### Optional Secrets (for notifications)

| Secret Name | Value | Description |
|------------|-------|-------------|
| `SLACK_WEBHOOK_URL` | `https://hooks.slack.com/services/...` | Slack incoming webhook |
| `ALERT_EMAIL` | `devops@company.com` | Email for drift alerts |
| `MAIL_SERVER` | `smtp.gmail.com` | SMTP server address |
| `MAIL_PORT` | `587` | SMTP port |
| `MAIL_USERNAME` | `alerts@company.com` | SMTP username |
| `MAIL_PASSWORD` | `app-specific-password` | SMTP password |

### Step 2.2: Create/Update GitHub Secrets

```bash
# Using GitHub CLI (recommended)
gh secret set AWS_ROLE_TO_ASSUME --body "arn:aws:iam::123456789012:role/github-actions-terraform-role"
gh secret set INFRACOST_API_KEY --body "YOUR_API_KEY"
gh secret set SLACK_WEBHOOK_URL --body "https://hooks.slack.com/..."

# Verify secrets are set
gh secret list
```

---

## Part 3: Infracost Setup

### Step 3.1: Get Infracost API Key

1. Visit [infracost.io](https://www.infracost.io/)
2. Sign up for free
3. Get your API key from the dashboard
4. Add to GitHub Secrets as `INFRACOST_API_KEY`

### Step 3.2: Verify Infracost

```bash
# Install Infracost locally to test
brew install infracost

# Run infracost in terraform directory
cd terraform
infracost breakdown --path .
```

---

## Part 4: Slack Integration

### Step 4.1: Create Slack Incoming Webhook

1. Go to [Slack Apps](https://api.slack.com/apps)
2. Click "Create New App" → "From scratch"
3. Name: "GitHub Terraform Alerts"
4. Select your workspace
5. Go to "Incoming Webhooks" → Enable
6. Click "Add New Webhook to Workspace"
7. Select channel where notifications should go
8. Copy the webhook URL

### Step 4.2: Add to GitHub Secrets

```bash
gh secret set SLACK_WEBHOOK_URL --body "https://hooks.slack.com/services/..."
```

### Step 4.3: Test Webhook

```bash
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test from GitHub Actions"}'
```

---

## Part 5: GitHub Branch Protection

### Step 5.1: Configure Branch Protection Rules

Go to: **Settings → Branches → Add Rule**

Settings:
- **Branch name pattern:** `main`
- ✅ **Require a pull request before merging**
- ✅ **Require status checks to pass:** Select:
  - `terraform-validate`
  - `security-scan`
  - `terraform-plan`
- ✅ **Require code reviews:** 1 approval
- ✅ **Dismiss stale pull request approvals**
- ✅ **Require status checks to pass before merging**
- ✅ **Allow auto merge:** Only for squash and rebase

---

## Part 6: Environment Configuration

### Step 6.1: Create GitHub Environments

Go to: **Settings → Environments → New environment**

Create environment: `production`

Settings:
- **Deployment branches:** `main` only
- **Required reviewers:** Add team members
- **Environment secrets:** (optional)
  - `TF_VAR_prod_flag` = `true`

---

## Part 7: Configure Workflows

### Step 7.1: Update Workflow Variables

Edit `.github/workflows/terraform-ci-cd.yml`:

```yaml
env:
  TERRAFORM_VERSION: 1.6.0
  AWS_REGION: us-east-1          # Change if needed
  CACHE_KEY_PREFIX: terraform-cache
```

### Step 7.2: Update Environment Variables

In each job, set:

```yaml
env:
  TF_VAR_environment: dev  # Change based on branch/environment
```

---

## Part 8: Workflow Triggers & Scheduling

### Trigger Configurations

**terraform-ci-cd.yml**
- ✅ Push to `main` and `develop`
- ✅ Pull requests to `main` and `develop`
- ✅ Manual (`workflow_dispatch`)

**terraform-drift-detection.yml**
- ✅ Scheduled daily at 08:00 UTC
- ✅ Manual (`workflow_dispatch`)

**terraform-cost-monitoring.yml**
- ✅ Scheduled weekly (Monday 09:00 UTC)
- ✅ Pull requests with terraform changes
- ✅ Manual (`workflow_dispatch`)

### Modify Schedules

Edit cron expressions in workflows:

```yaml
# Examples:
'0 8 * * *'    # Daily at 08:00 UTC
'0 9 * * 1'    # Weekly on Monday at 09:00 UTC
'0 */6 * * *'  # Every 6 hours
```

---

## Part 9: Monitoring & Debugging

### View Workflow Runs

1. Go to **Actions** tab in GitHub
2. Select workflow: `Terraform CI/CD Pipeline`
3. Click run to view logs
4. Click individual jobs to see details

### Common Issues

#### Issue: "OIDC token not found"
**Solution:**
- Verify IAM role trust relationship
- Check `token.actions.githubusercontent.com:sub` condition matches your repo

#### Issue: "Insufficient permissions"
**Solution:**
- Attach more permissive policy to IAM role
- For production: Use more restrictive policy

#### Issue: "Terraform init fails"
**Solution:**
- Check `TF_BACKEND_CONFIG` secrets
- Verify S3 bucket exists and is accessible
- Check IAM role has S3 permissions

### Debugging Commands

```bash
# View GitHub Actions logs
gh run list
gh run view <run-id> --log

# Check secrets
gh secret list

# Test OIDC token (from GitHub Actions)
# This runs inside the workflow
echo $ACTIONS_ID_TOKEN_REQUEST_URL
echo $ACTIONS_ID_TOKEN_REQUEST_TOKEN
```

---

## Part 10: Best Practices

### Security

✅ **Do:**
- Use OIDC for AWS credentials (no long-lived keys)
- Require approvals for production deployments
- Use branch protection rules
- Rotate Slack webhooks periodically
- Use specific IAM permissions (least privilege)

❌ **Don't:**
- Store AWS access keys in secrets
- Use admin IAM policies in production
- Push sensitive data to repositories
- Disable branch protection
- Use public runners for sensitive data

### Performance

✅ **Optimize:**
- Cache Terraform plugins
- Use `terraform init -backend=false` for validation
- Limit workflow triggers
- Archive old artifacts

❌ **Avoid:**
- Running unnecessary checks
- Large artifact retention
- Parallel workflows that block each other

### Maintenance

✅ **Maintain:**
- Update actions regularly
- Review workflow logs weekly
- Monitor cost trends
- Update drift detection rules
- Clean up old artifacts

---

## Part 11: Testing Workflows Locally

### Using Act (GitHub Actions Locally)

```bash
# Install act
brew install act

# List workflows
act -l

# Run specific workflow
act -j terraform-validate

# Run with specific secrets file
act --secret-file .env.local
```

Create `.env.local`:
```
AWS_ROLE_TO_ASSUME=arn:aws:iam::123456789012:role/github-actions-terraform-role
INFRACOST_API_KEY=your-api-key
```

---

## Part 12: Complete Setup Checklist

### Pre-Setup
- [ ] AWS Account created
- [ ] GitHub Repository created
- [ ] Terraform code ready
- [ ] Repository cloned locally

### AWS Setup
- [ ] OIDC provider created in AWS
- [ ] IAM role created and configured
- [ ] IAM role ARN copied

### GitHub Secrets
- [ ] `AWS_ROLE_TO_ASSUME` added
- [ ] `INFRACOST_API_KEY` added (if using Infracost)
- [ ] `SLACK_WEBHOOK_URL` added (if using Slack)

### Workflows
- [ ] `.github/workflows/` directory created
- [ ] All 3 workflow files added
- [ ] Workflow variables reviewed and updated
- [ ] Cron schedules set correctly

### Branch Protection
- [ ] Branch protection rules enabled for `main`
- [ ] Required status checks configured
- [ ] Approvals required

### Testing
- [ ] Create test PR to verify workflows
- [ ] Check terraform-validate passes
- [ ] Check security-scan completes
- [ ] Check terraform-plan generates output
- [ ] Merge PR to trigger apply

### Verification
- [ ] terraform apply completed successfully
- [ ] EC2 instances created
- [ ] CloudWatch alarms configured
- [ ] SNS topics created
- [ ] Slack notifications received

---

## Part 13: Troubleshooting Commands

```bash
# Check IAM role trust policy
aws iam get-role --role-name github-actions-terraform-role

# View role inline policies
aws iam list-role-policies --role-name github-actions-terraform-role

# Test OIDC provider
aws iam list-open-id-connect-providers

# View GitHub Actions run history
gh run list --repo YOUR_REPO

# Get detailed run logs
gh run view <run-id> --repo YOUR_REPO --log

# List secrets
gh secret list --repo YOUR_REPO

# Delete old artifacts
gh api repos/YOUR_ORG/YOUR_REPO/actions/artifacts
```

---

## Part 14: Next Steps

1. ✅ Complete setup checklist
2. ✅ Test with a simple PR
3. ✅ Monitor first production deployment
4. ✅ Adjust thresholds/alerts as needed
5. ✅ Add team members to environments
6. ✅ Document runbooks for incidents
7. ✅ Schedule team training on workflows

---

## Support & References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform GitHub Actions Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/users)
- [Infracost Documentation](https://www.infracost.io/docs/)

---

**Version:** 1.0  
**Last Updated:** 2024  
**Author:** Infrastructure Team
