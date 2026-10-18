data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  name_prefix = "${var.project_name}-${var.environment}"

  embedding_model_arn  = "arn:aws:bedrock:${local.region}::foundation-model/${var.embedding_model_id}"
  foundation_model_arn = "arn:aws:bedrock:${local.region}:${local.account_id}:inference-profile/us.${var.foundation_model_id}"

  vector_field   = "embedding"
  text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
  metadata_field = "AMAZON_BEDROCK_METADATA"
}
