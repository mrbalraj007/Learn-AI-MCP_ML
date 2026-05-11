#!/bin/bash

set -e

echo "Fetching ONLY unused customer-managed policies..."

POLICIES=$(aws iam list-policies \
  --scope Local \
  --query "Policies[?AttachmentCount==\`0\`].Arn" \
  --output text)

for POLICY in $POLICIES; do

  echo "Deleting unused policy: $POLICY"

  # delete non-default versions
  VERSIONS=$(aws iam list-policy-versions \
    --policy-arn "$POLICY" \
    --query 'Versions[?IsDefaultVersion==`false`].VersionId' \
    --output text)

  for V in $VERSIONS; do
    aws iam delete-policy-version \
      --policy-arn "$POLICY" \
      --version-id "$V"
  done

  aws iam delete-policy --policy-arn "$POLICY"

done

echo "DONE: only unused policies deleted safely"