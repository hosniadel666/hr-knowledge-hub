resource "aws_bedrockagent_knowledge_base" "hr_kb" {
  name     = "${local.name_prefix}-knowledge-base"
  role_arn = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = local.embedding_model_arn
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.hr_docs.arn
      vector_index_name = var.vector_index_name

      field_mapping {
        vector_field   = local.vector_field
        text_field     = local.text_field
        metadata_field = local.metadata_field
      }
    }
  }

  depends_on = [
    null_resource.opensearch_index,
    aws_iam_role_policy.bedrock_kb_s3,
    aws_iam_role_policy.bedrock_kb_aoss,
    aws_iam_role_policy.bedrock_kb_model,
  ]

  tags = var.tags
}

resource "aws_bedrockagent_data_source" "hr_s3" {
  knowledge_base_id    = aws_bedrockagent_knowledge_base.hr_kb.id
  name                 = "${local.name_prefix}-s3-data-source"
  data_deletion_policy = "RETAIN"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.hr_documents.arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"

      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}

resource "null_resource" "sync_data_source" {
  depends_on = [
    aws_bedrockagent_data_source.hr_s3,
    aws_s3_object.employee_handbook,
    aws_s3_object.leave_policy,
    aws_s3_object.benefits_faq,
    aws_s3_object.onboarding_guide,
  ]

  triggers = {
    documents_hash = sha256(join(",", [
      filemd5("${path.module}/../documents/employee-handbook.txt"),
      filemd5("${path.module}/../documents/leave-policy.txt"),
      filemd5("${path.module}/../documents/benefits-faq.txt"),
      filemd5("${path.module}/../documents/onboarding-guide.txt"),
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws bedrock-agent start-ingestion-job \
        --knowledge-base-id ${aws_bedrockagent_knowledge_base.hr_kb.id} \
        --data-source-id ${aws_bedrockagent_data_source.hr_s3.data_source_id} \
        --region ${var.region}
    EOT
  }
}
