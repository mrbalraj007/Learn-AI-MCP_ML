from pathlib import Path
p = Path('MyAgentCoreUserPolicy.txt')
text = p.read_text(encoding='utf-8')
# Remove literal UTF-8 BOM characters if present from repeated encoding
if text.startswith('\ufeff'):
    text = text.lstrip('\ufeff')
if text.startswith('ï»¿'):
    text = text[len('ï»¿'):]
if not text.lstrip().startswith('{'):
    raise SystemExit('Policy file does not start with { after BOM removal: %r' % text[:10])
# Ensure the new observability block exists.
if 'GenAIObservability' not in text:
    insert_point = text.rfind('"Sid": "S3AccessOptional"')
    if insert_point == -1:
        raise SystemExit('Cannot find S3AccessOptional block')
    # find end of S3 block
    end_brace = text.find('}', insert_point)
    if end_brace == -1:
        raise SystemExit('Cannot find end of S3AccessOptional block')
    insertion = '''
        {
            "Sid": "GenAIObservability",
            "Effect": "Allow",
            "Action": [
                "xray:UpdateTraceSegmentDestination",
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords",
                "xray:GetSamplingRules",
                "xray:GetSamplingTarget",
                "xray:GetSamplingStatisticSummaries",
                "logs:CreateLogDelivery",
                "logs:DeleteLogDelivery",
                "logs:DescribeLogDelivery",
                "logs:ListLogDeliveries",
                "logs:GetLogDelivery",
                "logs:UpdateLogDelivery",
                "logs:DescribeResourcePolicies",
                "logs:PutResourcePolicy",
                "logs:DescribeDestinations",
                "logs:PutDestination",
                "logs:DeleteDestination"
            ],
            "Resource": "*"
        },'''
    text = text[:end_brace+1] + insertion + text[end_brace+1:]
p.write_text(text, encoding='utf-8')
print('fixed')
