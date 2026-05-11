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
  --query "Stacks[0].Outputs"
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
