import json
import os

import boto3

bedrock_runtime = boto3.client(
    "bedrock-agent-runtime",
    region_name=os.environ["REGION"],
)

KNOWLEDGE_BASE_ID = os.environ["KNOWLEDGE_BASE_ID"]
MODEL_ARN = os.environ["FOUNDATION_MODEL_ARN"]


def handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        query = body.get("query", "")
        session_id = body.get("session_id")

        if not query:
            return _response(400, {"error": "Missing 'query' in request body"})

        params = {
            "input": {"text": query},
            "retrieveAndGenerateConfiguration": {
                "type": "KNOWLEDGE_BASE",
                "knowledgeBaseConfiguration": {
                    "knowledgeBaseId": KNOWLEDGE_BASE_ID,
                    "modelArn": MODEL_ARN,
                },
            },
        }

        if session_id:
            params["sessionId"] = session_id

        result = bedrock_runtime.retrieve_and_generate(**params)

        return _response(200, {
            "answer": result["output"]["text"],
            "session_id": result["sessionId"],
            "citations": [
                {
                    "text": citation.get("generatedResponsePart", {})
                        .get("textResponsePart", {})
                        .get("text", ""),
                    "references": [
                        ref.get("location", {})
                            .get("s3Location", {})
                            .get("uri", "")
                        for ref in citation.get("retrievedReferences", [])
                    ],
                }
                for citation in result.get("citations", [])
            ],
        })

    except Exception as e:
        print(f"Error: {e}")
        return _response(500, {"error": str(e)})


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
        },
        "body": json.dumps(body),
    }
