# myagent_with_memory.py
import json
import logging
import boto3
from bedrock_agentcore import BedrockAgentCoreApp

logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = BedrockAgentCoreApp()

# Ephemeral (in-memory) session memory
SESSION_MEMORY = {}

# Bedrock client using Converse API (model-agnostic)
bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

MODEL_ID = "amazon.nova-lite-v1:0"


@app.entrypoint
def invoke(payload):
    """
    Ephemeral conversational agent using Amazon Nova Lite via Bedrock Converse API.
    Session memory lasts only within the current runtime.
    """

    # Parse payload safely
    if isinstance(payload, (bytes, str)):
        try:
            payload = json.loads(payload)
        except Exception:
            payload = {}

    prompt = payload.get("prompt") or payload.get("input") or ""
    runtimeSessionId = payload.get("runtimeSessionId", "default-session")

    if not prompt:
        return {"message": "No prompt provided."}

    logger.info(f"Session: {runtimeSessionId}, Prompt: {prompt}")

    # Retrieve short-term conversation history
    history = SESSION_MEMORY.get(runtimeSessionId, [])

    # Build conversation messages
    messages = []
    for m in history:
        role = "user" if m["role"] == "user" else "assistant"
        messages.append({"role": role, "content": [{"text": m["text"]}]})

    # Append new user input
    messages.append({"role": "user", "content": [{"text": prompt}]})

    # Call via Bedrock Converse API
    try:
        response = bedrock.converse(
            modelId=MODEL_ID,
            messages=messages,
            inferenceConfig={"maxTokens": 512, "temperature": 0.7}
        )
        reply = response["output"]["message"]["content"][0]["text"]
    except Exception as e:
        logger.exception("Error calling Amazon Nova Lite:")
        reply = f"Error: {str(e)}"

    # Update ephemeral session memory (limit to last 10 turns)
    history.append({"role": "user", "text": prompt})
    history.append({"role": "assistant", "text": reply})
    SESSION_MEMORY[runtimeSessionId] = history[-10:]  # keep last 10 exchanges only

    return {"message": reply}


if __name__ == "__main__":
    app.run()