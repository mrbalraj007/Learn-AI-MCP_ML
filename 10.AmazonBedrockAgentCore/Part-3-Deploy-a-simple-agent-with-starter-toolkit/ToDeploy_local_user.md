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
agentcore --help

agentcore configure -e myagent.py

agentcore launch

compre two json file
https://jsondiff.com/
https://jsoncompare.org/

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