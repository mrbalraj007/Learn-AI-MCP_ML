Go to folder `/home/dc-ops/nvidia-nim` and run the following

```sh
uv run uvicorn server:app --host 0.0.0.0 --port 8082
```
in another windows

```sh
ANTHROPIC_AUTH_TOKEN="freecc" ANTHROPIC_BASE_URL="http://localhost:8082" claude
```
and enjoy the claude code in free.

# To activate the virtual environment in a new terminal, run:
```sh
source ~/bedrock-env/bin/activate
```

*** VERIFY THAT AGENTCORE IS INSTALLED ***
```sh
agentcore -V
agentcore --help
```
```sh
agentcore configure -e myllmagent.py
```
```sh
agentcore launch
```

# compre two json file
```sh
https://jsondiff.com/
https://jsoncompare.org/
```
Next Steps:
```sh
 agentcore status                                                
```                                                      

```sh                                                     
agentcore invoke '{"prompt": "Write a poem on Autumn"}'
```                                    
# To destroy the agentcore
```sh
agentcore destroy --agent myllmagent.py
agentcore destroy --agent myllmagent.py --force
```

**To find out all models in AWS**
```sh
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[*].{Provider:providerName,Model:modelId,Status:modelLifecycle.status}' \
  --output table
```

**To find out all models in AWS**
```sh
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[*].[providerName,modelId,modelLifecycle.status]' \
  --output table
```

**Filter Only Legacy Models**
```sh
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?modelLifecycle.status==`LEGACY`].[providerName,modelId]' \
  --output table
```

**Filter Only Active Models**
```sh
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?modelLifecycle.status==`ACTIVE`].[providerName,modelId]' \
  --output table
```

**Check Specific Model**
```sh
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?modelId==`anthropic.claude-v2`].[modelId,modelLifecycle.status]' \
  --output table
```

# Delete contents:
```sh
aws s3 rm s3://bedrock-agentcore-codebuild-sources-373160674113-us-east-1 --recursive
```
# Delete bucket:
```sh
aws s3 rb s3://bedrock-agentcore-codebuild-sources-373160674113-us-east-1
```

# Delete ALL private ECR repositories in an account/region
```sh
for repo in $(aws ecr describe-repositories \
  --query "repositories[].repositoryName" \
  --output text \
  --region us-east-1); do

  echo "Deleting $repo"

  aws ecr delete-repository \
    --repository-name "$repo" \
    --force \
    --region us-east-1

done
```

# Verify repositories
```sh
aws ecr describe-repositories --region us-east-1
```

Delete specific image instead of whole repo

Get image list:

aws ecr list-images \
  --repository-name my-agentcore-repo \
  --region us-east-1

Delete image:

aws ecr batch-delete-image \
  --repository-name my-agentcore-repo \
  --image-ids imageTag=latest \
  --region us-east-1

To delete a private Amazon ECR repository using AWS CLI:

aws ecr delete-repository \
  --repository-name <repository-name> \
  --force \
  --region <aws-region>

Example:

aws ecr delete-repository \
  --repository-name my-agentcore-repo \
  --force \
  --region us-east-1  




```sh
  Use this command to get only the delivery destination names:

aws logs describe-delivery-destinations \
  --region us-east-1 \
  --query "deliveryDestinations[].name" \
  --output text

One name per line:

aws logs describe-delivery-destinations \
  --region us-east-1 \
  --query "deliveryDestinations[].name" \
  --output text | tr '\t' '\n'
  ```

  # 1. See ALL delivery destinations and their names
```sh
aws logs describe-delivery-destinations \
  --region us-east-1 \
  --query 'deliveryDestinations[*].{Name:name,Arn:arn,Type:deliveryDestinationType}' \
  --output table
```
# 2. See the resource policy on each destination
```sh
aws logs describe-delivery-destinations \
  --region us-east-1 \
  --query 'deliveryDestinations[*].{Name:name,Policy:policyDocument}' \
  --output json
```
# 3. See existing deliveries (source→destination links)
```sh
aws logs describe-deliveries \
  --region us-east-1 \
  --output table
```
# 4. See delivery sources
```sh
aws logs describe-delivery-sources \
  --region us-east-1 \
  --output table
```

=================

```sh
mkdir -p terraform-myagentcore-iam && \
touch terraform-myagentcore-iam/{provider.tf,variables.tf,main.tf,iam-user.tf,iam-role.tf,iam-policies.tf,outputs.tf,MyAgentCoreUserPolicy.txt,MyAgentCoreExecutionRoleCustomPolicy.txt,MyAgentCoreExecutionRoleTrustPolicy.txt}
```

```sh
terraform output access_key_id
terraform output secret_access_key
```

```sh
aws iam list-roles \
--query 'Roles[*].[RoleName,RoleLastUsed.LastUsedDate]' \
--output table
```

