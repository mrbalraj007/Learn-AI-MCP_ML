# myllmagent.py
import json
import logging
import boto3
from bedrock_agentcore import BedrockAgentCoreApp

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize the agentcore app
app = BedrockAgentCoreApp()

# Initialize Bedrock client
bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')

MODEL_ID = "amazon.nova-lite-v1:0"

@app.entrypoint
def invoke(payload):
    """
    payload: dict from agentcore CLI, e.g. {"prompt": "..."}
    Returns JSON-serializable dict with key "message"
    """
    # Handle bytes/string payload
    if isinstance(payload, (bytes, str)):
        try:
            payload = json.loads(payload)
        except Exception:
            payload = {}

    # Extract prompt
    prompt = payload.get("prompt") or payload.get("input") or ""
    logger.info("Received prompt: %s", prompt)

    if not prompt:
        return {"message": "No prompt provided."}

    # Prepare request for Bedrock Nova model (Messages API)
    try:
        request_body = json.dumps({
            "messages": [
                {"role": "user", "content": [{"text": prompt}]}
            ]
        }).encode("utf-8")
        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=request_body,
            contentType="application/json",
            accept="application/json"
        )

        # Read response
        response_body = response['body'].read()
        model_output = json.loads(response_body)
        logger.info("Model output: %s", model_output)

        # Extract text from Nova Messages API response
        output_msg = model_output.get("output", {}).get("message", {})
        content = output_msg.get("content", [])
        text = content[0].get("text", str(model_output)) if content else str(model_output)
        return {"message": text}

    except Exception as e:
        logger.error("Error calling LLM: %s", e, exc_info=True)
        return {"message": f"Error calling LLM: {e}"}


if __name__ == "__main__":
    app.run()