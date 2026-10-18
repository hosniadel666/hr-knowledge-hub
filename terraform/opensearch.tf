# Encryption policy must exist before creating the collection.
# NOTE: Encryption policy uses a JSON object, NOT an array.
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.project_name}-enc"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        Resource     = ["collection/${var.project_name}"]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

# Network policy must exist before creating the collection.
# NOTE: Network policy uses a JSON array, NOT an object.
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.project_name}-net"
  type = "network"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource     = ["collection/${var.project_name}"]
          ResourceType = "collection"
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_collection" "hr_docs" {
  name             = var.project_name
  type             = "VECTORSEARCH"
  description      = "Vector store for HR Knowledge Hub document embeddings"
  standby_replicas = "DISABLED"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
  ]

  tags = var.tags
}

# Access policy grants the Bedrock KB role AND the Terraform executor
# permission to manage indexes and read/write documents.
resource "aws_opensearchserverless_access_policy" "hr_docs" {
  name = "${var.project_name}-access"
  type = "data"

  policy = jsonencode([
    {
      Description = "Access for Bedrock Knowledge Base and Terraform executor"
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${var.project_name}"]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems",
          ]
        },
        {
          ResourceType = "index"
          Resource     = ["index/${var.project_name}/*"]
          Permission = [
            "aoss:CreateIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:UpdateIndex",
            "aoss:DeleteIndex",
            "aoss:DescribeIndex",
          ]
        },
      ]
      Principal = [
        aws_iam_role.bedrock_kb.arn,
        data.aws_caller_identity.current.arn,
      ]
    }
  ])
}

resource "null_resource" "opensearch_index" {
  depends_on = [
    aws_opensearchserverless_collection.hr_docs,
    aws_opensearchserverless_access_policy.hr_docs,
  ]

  provisioner "local-exec" {
    command = "python3 ${path.module}/scripts/create_index.py"

    environment = {
      COLLECTION_ENDPOINT = aws_opensearchserverless_collection.hr_docs.collection_endpoint
      INDEX_NAME          = var.vector_index_name
      EMBEDDING_DIMENSION = tostring(var.embedding_dimensions)
      REGION              = var.region
    }
  }
}
