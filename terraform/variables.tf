variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hr-knowledge-hub"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "embedding_model_id" {
  description = "Bedrock embedding model ID for document vectorization"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "foundation_model_id" {
  description = "Bedrock foundation model for RAG answer generation"
  type        = string
  default     = "anthropic.claude-haiku-4-5-20251001-v1:0"
}

variable "embedding_dimensions" {
  description = "Vector dimensions for the embedding model"
  type        = number
  default     = 1024
}

variable "vector_index_name" {
  description = "Name of the OpenSearch vector index"
  type        = string
  default     = "hr-docs-index"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "hr-knowledge-hub"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
