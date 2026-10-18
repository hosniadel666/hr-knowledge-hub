#!/usr/bin/env python3
"""Create OpenSearch Serverless vector index for Bedrock Knowledge Base."""

import json
import os
import time

import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

endpoint = os.environ["COLLECTION_ENDPOINT"].replace("https://", "")
index_name = os.environ["INDEX_NAME"]
dimension = int(os.environ["EMBEDDING_DIMENSION"])
region = os.environ["REGION"]

credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    "aoss",
    session_token=credentials.token,
)

client = OpenSearch(
    hosts=[{"host": endpoint, "port": 443}],
    http_auth=awsauth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection,
    timeout=300,
)

index_body = {
    "settings": {
        "index": {
            "knn": True,
            "knn.algo_param.ef_search": 512,
        }
    },
    "mappings": {
        "properties": {
            "embedding": {
                "type": "knn_vector",
                "dimension": dimension,
                "method": {
                    "engine": "faiss",
                    "name": "hnsw",
                    "space_type": "l2",
                    "parameters": {
                        "ef_construction": 512,
                        "m": 16,
                    },
                },
            },
            "AMAZON_BEDROCK_TEXT_CHUNK": {"type": "text"},
            "AMAZON_BEDROCK_METADATA": {"type": "text"},
        }
    },
}

MAX_RETRIES = 5
for attempt in range(MAX_RETRIES):
    try:
        if not client.indices.exists(index=index_name):
            client.indices.create(index=index_name, body=index_body)
            print(f"Created index: {index_name}")
        else:
            print(f"Index already exists: {index_name}")
        break
    except Exception as e:
        if attempt < MAX_RETRIES - 1:
            wait = 30 * (attempt + 1)
            print(f"Attempt {attempt + 1} failed: {e}. Retrying in {wait}s...")
            time.sleep(wait)
        else:
            raise
