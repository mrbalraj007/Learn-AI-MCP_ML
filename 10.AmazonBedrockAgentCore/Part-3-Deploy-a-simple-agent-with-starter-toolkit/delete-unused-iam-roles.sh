#!/bin/bash

# ============================================================
# AWS IAM Unused Role Cleanup Script
# Author  : AWS Engineer
# Purpose : Identify and delete unused IAM roles safely
# ============================================================


#============================================================
# How to Use

# 1. Save Script
# vi delete-unused-iam-roles.sh

# Paste the script.

# 2. Make Executable
# chmod +x delete-unused-iam-roles.sh

# 3. Dry Run (Recommended First)

# By default:
# DRY_RUN=true

# Run:
# ./delete-unused-iam-roles.sh

# This only shows what would be deleted.

# 4. Interactive Delete
# Change:
# DRY_RUN=false
# AUTO_DELETE=false

# Then run:

# ./delete-unused-iam-roles.sh

# You will be prompted for each role.

# 5. Automatic Delete

# Change:
# DRY_RUN=false
# AUTO_DELETE=true

# Then run:
# ./delete-unused-iam-roles.sh
# ============================================================ 
set -euo pipefail

# -----------------------------
# CONFIGURATION
# -----------------------------

UNUSED_DAYS=90
DRY_RUN=true # true for dry run, false to enable deletion
AUTO_DELETE=false # true to auto delete without confirmation, false to prompt for each role

# -----------------------------
# FUNCTIONS
# -----------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

delete_role() {

    ROLE_NAME="$1"

    log "Starting cleanup for role: $ROLE_NAME"

    # ---------------------------------------------------
    # Delete inline policies
    # ---------------------------------------------------

    INLINE_POLICIES=$(aws iam list-role-policies \
        --role-name "$ROLE_NAME" \
        --query 'PolicyNames' \
        --output text)

    for POLICY in $INLINE_POLICIES; do
        log "Deleting inline policy: $POLICY"

        aws iam delete-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-name "$POLICY"
    done

    # ---------------------------------------------------
    # Detach managed policies
    # ---------------------------------------------------

    MANAGED_POLICIES=$(aws iam list-attached-role-policies \
        --role-name "$ROLE_NAME" \
        --query 'AttachedPolicies[].PolicyArn' \
        --output text)

    for POLICY_ARN in $MANAGED_POLICIES; do
        log "Detaching managed policy: $POLICY_ARN"

        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "$POLICY_ARN"
    done

    # ---------------------------------------------------
    # Remove from instance profiles
    # ---------------------------------------------------

    INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role \
        --role-name "$ROLE_NAME" \
        --query 'InstanceProfiles[].InstanceProfileName' \
        --output text)

    for PROFILE in $INSTANCE_PROFILES; do

        log "Removing role from instance profile: $PROFILE"

        aws iam remove-role-from-instance-profile \
            --instance-profile-name "$PROFILE" \
            --role-name "$ROLE_NAME"

        log "Deleting instance profile: $PROFILE"

        aws iam delete-instance-profile \
            --instance-profile-name "$PROFILE"
    done

    # ---------------------------------------------------
    # Delete role
    # ---------------------------------------------------

    log "Deleting role: $ROLE_NAME"

    aws iam delete-role \
        --role-name "$ROLE_NAME"

    log "SUCCESS: Deleted role $ROLE_NAME"
}

# -----------------------------
# MAIN
# -----------------------------

log "Fetching IAM roles..."

ROLES=$(aws iam list-roles \
    --query 'Roles[].RoleName' \
    --output text)

CURRENT_EPOCH=$(date +%s)

for ROLE in $ROLES; do

    # Skip AWS service-linked roles
    if [[ "$ROLE" == AWSServiceRoleFor* ]]; then
        log "Skipping AWS service-linked role: $ROLE"
        continue
    fi

    log "Checking role: $ROLE"

    ROLE_JSON=$(aws iam get-role --role-name "$ROLE")

    LAST_USED=$(echo "$ROLE_JSON" | jq -r '.Role.RoleLastUsed.LastUsedDate // empty')

    # If never used
    if [[ -z "$LAST_USED" ]]; then
        log "Role NEVER USED: $ROLE"

        SHOULD_DELETE=true

    else

        LAST_USED_EPOCH=$(date -d "$LAST_USED" +%s)

        DIFF_DAYS=$(( (CURRENT_EPOCH - LAST_USED_EPOCH) / 86400 ))

        log "Last used $DIFF_DAYS days ago"

        if (( DIFF_DAYS > UNUSED_DAYS )); then
            SHOULD_DELETE=true
        else
            SHOULD_DELETE=false
        fi
    fi

    # ---------------------------------------------------
    # DELETE LOGIC
    # ---------------------------------------------------

    if [[ "$SHOULD_DELETE" == true ]]; then

        log "Unused role detected: $ROLE"

        if [[ "$DRY_RUN" == true ]]; then

            log "[DRY RUN] Would delete role: $ROLE"

        else

            if [[ "$AUTO_DELETE" == true ]]; then

                delete_role "$ROLE"

            else

                read -p "Delete role $ROLE ? (yes/no): " ANSWER

                if [[ "$ANSWER" == "yes" ]]; then
                    delete_role "$ROLE"
                else
                    log "Skipped role: $ROLE"
                fi
            fi
        fi

    else

        log "Role recently used. Skipping."

    fi

    echo "------------------------------------------------"

done

log "IAM cleanup completed."