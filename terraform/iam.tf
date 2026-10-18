# =============================================================================
# Bedrock Knowledge Base Role
# =============================================================================

data "aws_iam_policy_document" "bedrock_kb_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:bedrock:${local.region}:${local.account_id}:knowledge-base/*"]
    }
  }
}

resource "aws_iam_role" "bedrock_kb" {
  name               = "${local.name_prefix}-bedrock-kb-role"
  assume_role_policy = data.aws_iam_policy_document.bedrock_kb_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "bedrock_kb_s3" {
  statement {
    sid       = "S3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.hr_documents.arn]
  }

  statement {
    sid       = "S3GetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.hr_documents.arn}/*"]
  }
}

resource "aws_iam_role_policy" "bedrock_kb_s3" {
  name   = "${local.name_prefix}-bedrock-kb-s3"
  role   = aws_iam_role.bedrock_kb.id
  policy = data.aws_iam_policy_document.bedrock_kb_s3.json
}

data "aws_iam_policy_document" "bedrock_kb_aoss" {
  statement {
    sid       = "OpenSearchServerlessAccess"
    effect    = "Allow"
    actions   = ["aoss:APIAccessAll"]
    resources = [aws_opensearchserverless_collection.hr_docs.arn]
  }
}

resource "aws_iam_role_policy" "bedrock_kb_aoss" {
  name   = "${local.name_prefix}-bedrock-kb-aoss"
  role   = aws_iam_role.bedrock_kb.id
  policy = data.aws_iam_policy_document.bedrock_kb_aoss.json
}

data "aws_iam_policy_document" "bedrock_kb_model" {
  statement {
    sid       = "BedrockInvokeModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = [local.embedding_model_arn]
  }
}

resource "aws_iam_role_policy" "bedrock_kb_model" {
  name   = "${local.name_prefix}-bedrock-kb-model"
  role   = aws_iam_role.bedrock_kb.id
  policy = data.aws_iam_policy_document.bedrock_kb_model.json
}

# =============================================================================
# Lambda Execution Role
# =============================================================================

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_bedrock" {
  statement {
    sid    = "BedrockRetrieveAndGenerate"
    effect = "Allow"
    actions = [
      "bedrock:RetrieveAndGenerate",
      "bedrock:Retrieve",
    ]
    resources = ["arn:aws:bedrock:${local.region}:${local.account_id}:knowledge-base/*"]
  }

  statement {
    sid    = "BedrockInvokeModel"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:GetInferenceProfile",
    ]
    resources = [
      local.foundation_model_arn,
      "arn:aws:bedrock:*::foundation-model/${var.foundation_model_id}",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_bedrock" {
  name   = "${local.name_prefix}-lambda-bedrock"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_bedrock.json
}
