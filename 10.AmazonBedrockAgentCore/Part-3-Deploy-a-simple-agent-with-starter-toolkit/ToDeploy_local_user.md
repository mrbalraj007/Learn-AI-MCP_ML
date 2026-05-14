# TO Deploy it 
```bash
aws cloudformation deploy \
  --stack-name MyAgentCoreStack \
  --template-file MyAgentCoreUser-CFN.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```


Once deployed, grab your keys from the Outputs tab in the CloudFormation console or via CLI:
```bash
aws cloudformation describe-stacks \
  --stack-name MyAgentCoreStack \
  --region us-east-1 \
  --query "Stacks[0].Outputs" \
  --output table
```
# To update stack
```sh
aws cloudformation update-stack \
  --stack-name MyAgentCoreStack \
  --template-body file://MyAgentCoreUser-CFN.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

# Watch update progress
```sh
aws cloudformation wait stack-update-complete \
  --stack-name MyAgentCoreStack \
  --region us-east-1
```

# TO delete it 
```bash
aws cloudformation delete-stack \
  --stack-name MyAgentCoreStack \
  --region us-east-1
```
# To monitor deletion progress:
```bash
aws cloudformation describe-stacks \
  --stack-name MyAgentCoreStack \
  --region us-east-1 \
  --query "Stacks[0].StackStatus"
```



If the stack is still stuck in UPDATE_FAILED, roll it back first, then re-apply:
bash# 1. Roll back to stable state
aws cloudformation continue-update-rollback \
  --stack-name <your-stack-name> \
  --region us-east-1

# 2. Wait for ROLLBACK_COMPLETE, then re-apply
aws cloudformation update-stack \
  --stack-name <your-stack-name> \
  --template-body file://MyAgentCore-IAM-Stack-v7.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1



Once deleted it will return ValidationError: Stack with id MyAgentCoreStack does not exist — that confirms it's fully gone.

Note: The IAM Access Key is also deleted automatically since it's part of the stack. No manual cleanup needed.


rm -rf ~/bedrock-env

```bash
# Step 1 - remove the broken venv
rm -rf ~/bedrock-env

# Step 2 - force reinstall the venv package properly
sudo apt-get install -y --reinstall python3.10-venv python3-full

# Step 3 - verify it works
python3 -c "import ensurepip, venv && echo OK"

# Step 4 - re-run the script
./setup-bedrock-env.sh
```

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
agentcore configure -e myagent.py
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
 agentcore status                                                  ```                                                      

```sh                                                     agentcore invoke '{"prompt": "Hello"}'
```                                    
# To destroy the agentcore
```sh
agentcore destroy --agent myagent
agentcore destroy --agent myagent --force
```

# Wait for update, then wait 15 mins for X-Ray destination to go ACTIVE, then:
agentcore launch


If it still fails
Make sure the AWS credentials used by agentcore deploy are the same IAM user updated by this CloudFormation stack.
If the old delivery destination is stale, delete the existing CloudWatch Logs delivery/destination resources and retry so it can recreate them cleanly.

Option 1: Use the stack-created user's credentials
On the VM where you run agentcore deploy:

Configure the MyAgentCoreUser access key/secret:

Use that profile when deploying:

AWS_PROFILE=myagentcoreuser agentcore deploy

Also Clean S3 Bucket Created Earlier

Your deployment created:

bedrock-agentcore-codebuild-sources-373160674113-us-east-1

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
aws logs describe-delivery-destinations \
  --region us-east-1 \
  --query 'deliveryDestinations[*].{Name:name,Arn:arn,Type:deliveryDestinationType}' \
  --output table

# 2. See the resource policy on each destination
aws logs describe-delivery-destinations \
  --region us-east-1 \
  --query 'deliveryDestinations[*].{Name:name,Policy:policyDocument}' \
  --output json

# 3. See existing deliveries (source→destination links)
aws logs describe-deliveries \
  --region us-east-1 \
  --output table

# 4. See delivery sources
aws logs describe-delivery-sources \
  --region us-east-1 \
  --output table


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

