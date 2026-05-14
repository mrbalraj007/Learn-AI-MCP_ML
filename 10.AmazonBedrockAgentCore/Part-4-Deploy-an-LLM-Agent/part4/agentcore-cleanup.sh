#!/usr/bin/env bash
# ==============================================================================
# agentcore-cleanup.sh
# Destroy ALL resources created by "agentcore launch" for a given agent.
# Usage: ./agentcore-cleanup.sh [--dry-run] [--agent AGENT_NAME]
# ==============================================================================
set -euo pipefail

AGENT_NAME="${AGENT_NAME:-myllmagent}"
REGION="${REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-373160674113}"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --agent)   AGENT_NAME="$2"; shift ;;
    esac
    shift 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

run() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${CYAN}[DRY-RUN]${NC} $*"
    else
        echo -e "  ${YELLOW}[RUN]${NC} $*"
        eval "$@"
    fi
}

echo "============================================================================="
echo " Cleaning up agent: ${RED}${AGENT_NAME}${NC}  |  Region: ${CYAN}${REGION}${NC}  |  Account: ${CYAN}${ACCOUNT_ID}${NC}"
[ "$DRY_RUN" = true ] && echo " >>> DRY RUN -- nothing will actually be deleted <<<"
echo "============================================================================="
echo ""

# ---- source the venv so agentcore/aws are available ----
source ~/bedrock-env/bin/activate

# ============================================================================
# 1. agentcore destroy (handles endpoint, runtime, CodeBuild, IAM role, ECR images)
# ============================================================================
echo -e "${GREEN}[1/7]${NC} agentcore destroy (endpoint, runtime, CodeBuild, IAM, ECR images)"

AGENT_ARGS="--agent ${AGENT_NAME} --force"
DRY_ARGS="$([ "$DRY_RUN" = true ] && echo '--dry-run' || true)"
CONFIG_FILE="$(pwd)/.bedrock_agentcore.yaml"

if [ -f "$CONFIG_FILE" ]; then
    # Try destroy; don't abort the script if it fails (e.g. stale config)
    run "agentcore destroy ${AGENT_ARGS} --delete-ecr-repo ${DRY_ARGS}" || \
        echo -e "  ${YELLOW}[WARN]${NC} agentcore destroy failed — will still clean cloud resources manually"
else
    echo "  No .bedrock_agentcore.yaml found — skipping agentcore destroy, proceeding with manual cleanup"
fi

# ============================================================================
# 2. Memory resource (may not be cleaned by destroy)
# ============================================================================
echo -e "${GREEN}[2/6]${NC} Delete memory resources"

MEM_IDS=$(agentcore memory list 2>/dev/null | grep -oP "${AGENT_NAME}_mem-\S+" || true)

if [ -n "$MEM_IDS" ] && [ "$MEM_IDS" != "None" ]; then
    for mem_id in $MEM_IDS; do
        echo "  Found memory: ${mem_id}"
        run "agentcore memory delete ${mem_id} --wait"
    done
else
    echo "  No memory resources found for ${AGENT_NAME}"
fi

# ============================================================================
# 3. S3 CodeBuild sources bucket
# ============================================================================
echo -e "${GREEN}[3/6]${NC} Delete S3 CodeBuild sources bucket"
BUCKET="bedrock-agentcore-codebuild-sources-${ACCOUNT_ID}-${REGION}"

if aws s3 ls "s3://${BUCKET}" --region "$REGION" &>/dev/null; then
    run "aws s3 rm s3://${BUCKET} --recursive --region ${REGION}"
    run "aws s3 rb s3://${BUCKET} --region ${REGION}"
else
    echo "  Bucket ${BUCKET} does not exist (already deleted)"
fi

# ============================================================================
# 4. CloudWatch Log Groups for the agent runtime
# ============================================================================
echo -e "${GREEN}[4/6]${NC} Delete CloudWatch Log Groups"

LOG_GROUP_PREFIX="/aws/bedrock-agentcore/runtimes/${AGENT_NAME}"

LOG_GROUPS=$(aws logs describe-log-groups \
    --region "$REGION" \
    --log-group-name-prefix "$LOG_GROUP_PREFIX" \
    --query 'logGroups[].logGroupName' \
    --output text 2>/dev/null || true)

if [ -n "$LOG_GROUPS" ] && [ "$LOG_GROUPS" != "None" ]; then
    for lg in $LOG_GROUPS; do
        echo "  Found log group: ${lg}"
        run "aws logs delete-log-group --log-group-name ${lg} --region ${REGION}"
    done
else
    echo "  No log groups found under ${LOG_GROUP_PREFIX}"
fi

# ============================================================================
# 5. X-Ray / CloudWatch delivery destinations (stale ones from agentcore)
# ============================================================================
echo -e "${GREEN}[5/6]${NC} Delete stale CloudWatch Log delivery destinations"

DELIVERY_NAMES=$(aws logs describe-delivery-destinations \
    --region "$REGION" \
    --query "deliveryDestinations[?contains(name, '${AGENT_NAME}')].name" \
    --output text 2>/dev/null || true)

if [ -n "$DELIVERY_NAMES" ] && [ "$DELIVERY_NAMES" != "None" ]; then
    for name in $DELIVERY_NAMES; do
        echo "  Found delivery destination: ${name}"
        run "aws logs delete-delivery-destination --name ${name} --region ${REGION}"
    done
else
    echo "  No delivery destinations found for ${AGENT_NAME}"
fi

# ============================================================================
# 6. ECR repositories (any left over with agent name)
# ============================================================================
echo -e "${GREEN}[6/6]${NC} Verify no leftover ECR repos"

LEFT_ECR=$(aws ecr describe-repositories \
    --region "$REGION" \
    --query "repositories[?contains(repositoryName, '${AGENT_NAME}')].repositoryName" \
    --output text 2>/dev/null || true)

if [ -n "$LEFT_ECR" ] && [ "$LEFT_ECR" != "None" ]; then
    for repo in $LEFT_ECR; do
        echo "  Leftover ECR repo: ${repo}"
        run "aws ecr delete-repository --repository-name ${repo} --force --region ${REGION}"
    done
else
    echo "  No leftover ECR repos"
fi

# ============================================================================
echo ""
echo "============================================================================="
echo -e " ${GREEN}Cleanup complete for agent: ${RED}${AGENT_NAME}${NC}"
[ "$DRY_RUN" = true ] && echo -e " ${CYAN}This was a dry run. Remove --dry-run to actually delete resources.${NC}"
echo "============================================================================="