#!/usr/bin/env bash
# ==============================================================================
# agentcore-cleanup.sh
# Destroy ALL resources created by "agentcore launch/deploy" for a given agent.
#
# Usage:
#   ./agentcore-cleanup.sh <AGENT_NAME>           # Clean up by name
#   ./agentcore-cleanup.sh --agent <AGENT_NAME>   # Clean up by flag
#   ./agentcore-cleanup.sh                        # Reads agent name from .bedrock_agentcore.yaml
#   ./agentcore-cleanup.sh --dry-run <AGENT_NAME> # Preview what will be deleted
#   REGION=us-west-2 ./agentcore-cleanup.sh ...   # Override region
# Usage — agent name from the terminal:
#  ./agentcore-cleanup.sh myagentwithsesmgmt          # positional
#  ./agentcore-cleanup.sh --agent myagentwithsesmgmt   # via flag
#  ./agentcore-cleanup.sh                              # auto-detects from .bedrock_agentcore.yaml
#  ./agentcore-cleanup.sh -n myagentwithsesmgmt        # dry-run preview
# ==============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
AGENT_NAME=""
REGION="${REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-373160674113}"
DRY_RUN=false

usage() {
    echo "Usage: $0 [--dry-run] [--agent] <AGENT_NAME>"
    echo ""
    echo "  AGENT_NAME          Name of the agent to clean up (positional, or use --agent)"
    echo "  --agent, -a NAME    Specify agent name explicitly"
    echo "  --dry-run, -n       Preview only, don't delete anything"
    echo "  REGION=us-west-2    Override region (default: us-east-1)"
    echo "  ACCOUNT_ID=123      Override AWS account ID"
    echo ""
    echo "If no agent name is given, it will be read from .bedrock_agentcore.yaml"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --agent|-a)
            if [[ -z "${2:-}" || "$2" == -* ]]; then
                echo "ERROR: --agent requires a value"
                usage
            fi
            AGENT_NAME="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        -*)
            echo "ERROR: Unknown flag: $1"
            usage
            ;;
        *)
            # Positional argument — first non-flag becomes agent name
            if [[ -z "$AGENT_NAME" ]]; then
                AGENT_NAME="$1"
            else
                echo "ERROR: Unexpected argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Auto-detect agent name from .bedrock_agentcore.yaml if not provided
# ---------------------------------------------------------------------------
if [[ -z "$AGENT_NAME" ]]; then
    CONFIG_FILE="$(pwd)/.bedrock_agentcore.yaml"
    if [[ -f "$CONFIG_FILE" ]]; then
        AGENT_NAME=$(grep -oP '^\s*default_agent:\s*\K\S+' "$CONFIG_FILE" 2>/dev/null || true)
        if [[ -n "$AGENT_NAME" ]]; then
            echo "Auto-detected agent name from .bedrock_agentcore.yaml: ${AGENT_NAME}"
        fi
    fi
fi

if [[ -z "$AGENT_NAME" ]]; then
    echo "ERROR: No agent name provided. Pass it as an argument or place .bedrock_agentcore.yaml in the current directory."
    usage
fi

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
echo " Cleaning up agent: ${RED}${AGENT_NAME}${NC}"
echo " Region: ${CYAN}${REGION}${NC}  |  Account: ${CYAN}${ACCOUNT_ID}${NC}"
[ "$DRY_RUN" = true ] && echo -e " ${YELLOW}>>> DRY RUN -- nothing will actually be deleted <<<${NC}"
echo "============================================================================="
echo ""

# ---------------------------------------------------------------------------
# Source venv if available (skip if it doesn't exist)
# ---------------------------------------------------------------------------
VENV_PATHS=("$HOME/bedrock-env/bin/activate" "$HOME/.venv/bin/activate" "./venv/bin/activate" "./.venv/bin/activate")
for vp in "${VENV_PATHS[@]}"; do
    if [[ -f "$vp" ]]; then
        source "$vp"
        break
    fi
done

# ============================================================================
# 1. agentcore destroy (runtime, endpoint, CodeBuild project, IAM role, ECR)
# ============================================================================
echo -e "${GREEN}[1/7]${NC} agentcore destroy"
CONFIG_FILE="$(pwd)/.bedrock_agentcore.yaml"

if [[ -f "$CONFIG_FILE" ]]; then
    AGENT_ARGS="--agent ${AGENT_NAME} --force"
    DRY_ARGS="$([ "$DRY_RUN" = true ] && echo '--dry-run' || true)"
    run "agentcore destroy ${AGENT_ARGS} --delete-ecr-repo ${DRY_ARGS}" || \
        echo -e "  ${YELLOW}[WARN]${NC} agentcore destroy failed — will still attempt manual cleanup"
else
    echo "  No .bedrock_agentcore.yaml found in $(pwd) — skipping agentcore destroy, proceeding with manual cleanup"
fi

# ============================================================================
# 2. AgentCore Memory resources
# ============================================================================
echo -e "${GREEN}[2/7]${NC} Delete AgentCore memory resources"

MEM_IDS=$(agentcore memory list 2>/dev/null | grep -oP "${AGENT_NAME}_mem-\S+" || true)

if [[ -n "$MEM_IDS" ]]; then
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
echo -e "${GREEN}[3/7]${NC} Delete S3 CodeBuild sources bucket"
BUCKET="bedrock-agentcore-codebuild-sources-${ACCOUNT_ID}-${REGION}"

if aws s3 ls "s3://${BUCKET}" --region "$REGION" &>/dev/null; then
    run "aws s3 rm s3://${BUCKET} --recursive --region ${REGION}"
    run "aws s3 rb s3://${BUCKET} --region ${REGION}"
else
    echo "  Bucket ${BUCKET} does not exist (already deleted)"
fi

# ============================================================================
# 4. CloudWatch Log Groups for agent runtime + CodeBuild
# ============================================================================
echo -e "${GREEN}[4/7]${NC} Delete CloudWatch Log Groups"

LOG_GROUP_PREFIXES=(
    "/aws/bedrock-agentcore/runtimes/${AGENT_NAME}"
    "/aws/codebuild/${AGENT_NAME}"
)

FOUND_ANY=false
for PREFIX in "${LOG_GROUP_PREFIXES[@]}"; do
    LOG_GROUPS=$(aws logs describe-log-groups \
        --region "$REGION" \
        --log-group-name-prefix "$PREFIX" \
        --query 'logGroups[].logGroupName' \
        --output text 2>/dev/null || true)

    if [[ -n "$LOG_GROUPS" && "$LOG_GROUPS" != "None" ]]; then
        for lg in $LOG_GROUPS; do
            echo "  Found log group: ${lg}"
            run "aws logs delete-log-group --log-group-name ${lg} --region ${REGION}"
            FOUND_ANY=true
        done
    fi
done

if [ "$FOUND_ANY" = false ]; then
    echo "  No log groups found for ${AGENT_NAME}"
fi

# ============================================================================
# 5. CloudWatch delivery destinations (stale ones from agentcore)
# ============================================================================
echo -e "${GREEN}[5/7]${NC} Delete stale CloudWatch deliveries + destinations"

# 5a. First, find and delete deliveries that reference agent-related destinations
DELIVERY_DEST_NAMES=$(aws logs describe-delivery-destinations \
    --region "$REGION" \
    --query "deliveryDestinations[?contains(name, '${AGENT_NAME}')].name" \
    --output text 2>/dev/null || true)

if [[ -n "$DELIVERY_DEST_NAMES" && "$DELIVERY_DEST_NAMES" != "None" ]]; then
    for dest_name in $DELIVERY_DEST_NAMES; do
        echo "  Found delivery destination: ${dest_name}"

        # Find and delete deliveries targeting this destination
        DELIVERY_IDS=$(aws logs describe-deliveries \
            --region "$REGION" \
            --query "deliveries[?deliveryDestinationName=='${dest_name}'].id" \
            --output text 2>/dev/null || true)

        if [[ -n "$DELIVERY_IDS" && "$DELIVERY_IDS" != "None" ]]; then
            for del_id in $DELIVERY_IDS; do
                echo "    Found delivery referencing destination: ${del_id}"
                run "aws logs delete-delivery --id ${del_id} --region ${REGION}"
            done
        fi

        # Now delete the destination itself
        run "aws logs delete-delivery-destination --name ${dest_name} --region ${REGION}"
    done
else
    echo "  No delivery destinations found for ${AGENT_NAME}"
fi

# ============================================================================
# 6. ECR repositories (any left over with agent name in it)
# ============================================================================
echo -e "${GREEN}[6/7]${NC} Delete leftover ECR repositories"

LEFT_ECR=$(aws ecr describe-repositories \
    --region "$REGION" \
    --query "repositories[?contains(repositoryName, '${AGENT_NAME}')].repositoryName" \
    --output text 2>/dev/null || true)

if [[ -n "$LEFT_ECR" && "$LEFT_ECR" != "None" ]]; then
    for repo in $LEFT_ECR; do
        echo "  Leftover ECR repo: ${repo}"
        run "aws ecr delete-repository --repository-name ${repo} --force --region ${REGION}"
    done
else
    echo "  No leftover ECR repos"
fi

# ============================================================================
# 7. IAM roles created by agentcore (agent-specific)
# ============================================================================
echo -e "${GREEN}[7/7]${NC} Delete leftover IAM roles"

LEFT_ROLES=$(aws iam list-roles \
    --query "Roles[?contains(RoleName, '${AGENT_NAME}')].RoleName" \
    --output text 2>/dev/null || true)

if [[ -n "$LEFT_ROLES" && "$LEFT_ROLES" != "None" ]]; then
    for role in $LEFT_ROLES; do
        echo "  Found IAM role: ${role}"
        # Detach all attached policies first
        POLICIES=$(aws iam list-attached-role-policies --role-name "$role" \
            --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || true)
        for pa in $POLICIES; do
            run "aws iam detach-role-policy --role-name ${role} --policy-arn ${pa}"
        done
        # Remove inline policies
        INLINE=$(aws iam list-role-policies --role-name "$role" \
            --query 'PolicyNames[]' --output text 2>/dev/null || true)
        for ip in $INLINE; do
            run "aws iam delete-role-policy --role-name ${role} --policy-name ${ip}"
        done
        run "aws iam delete-role --role-name ${role}"
    done
else
    echo "  No leftover IAM roles"
fi

# ============================================================================
echo ""
echo "============================================================================="
echo -e " ${GREEN}Cleanup complete for agent: ${RED}${AGENT_NAME}${NC}"
[ "$DRY_RUN" = true ] && echo -e " ${CYAN}This was a dry run. Remove --dry-run to actually delete resources.${NC}"
echo "============================================================================="